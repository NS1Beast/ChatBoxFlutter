using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using System.Security.Claims;
using System.Text.Json; // 🎯 Cần thiết cho JsonDocument
using System.Collections.Concurrent; // 🎯 Cần thiết cho Sổ điểm danh đa luồng
using ChatApp.Api.Models;
using ChatApp.Api.Services;

namespace ChatApp.Api.Hubs
{
    [Authorize]
    public class ChatHub : Hub
    {
        private readonly ChatDbContext _db;
        private readonly EncryptionService _crypto;
        private readonly IMemoryCache _cache;
        private readonly MessageQueue _queue;

        // 🎯 SỔ ĐIỂM DANH: Lưu userId và danh sách connectionId đang online của user đó
        private static readonly ConcurrentDictionary<string, HashSet<string>> _onlineUsers =
            new(StringComparer.OrdinalIgnoreCase);

        // 🎯 Khóa để tránh lỗi đa luồng khi thêm/xóa connectionId trong HashSet
        private static readonly object _onlineUsersLock = new();

        public ChatHub(ChatDbContext db, EncryptionService crypto, IMemoryCache cache, MessageQueue queue)
        {
            _db = db;
            _crypto = crypto;
            _cache = cache;
            _queue = queue;
        }

        // ==========================================
        // 🎯 LOGIC ONLINE / OFFLINE BẮT ĐẦU Ở ĐÂY
        // ==========================================

        public override async Task OnConnectedAsync()
        {
            var userId = Context.UserIdentifier;

            if (!string.IsNullOrWhiteSpace(userId))
            {
                bool isFirstConnection = false;

                lock (_onlineUsersLock)
                {
                    if (!_onlineUsers.TryGetValue(userId, out var connections))
                    {
                        connections = new HashSet<string>();
                        _onlineUsers[userId] = connections;
                    }

                    // Nếu trước đó user chưa có connection nào thì đây là lần online đầu tiên
                    isFirstConnection = connections.Count == 0;

                    connections.Add(Context.ConnectionId);
                }

                Console.WriteLine($"🟢 User online: {userId} | ConnectionId: {Context.ConnectionId}");

                if (isFirstConnection)
                {
                    // Báo cho các client khác biết user này vừa online
                    await Clients.Others.SendAsync("UserOnline", userId);
                }
            }

            await base.OnConnectedAsync();
        }

        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            var userId = Context.UserIdentifier;

            if (!string.IsNullOrWhiteSpace(userId))
            {
                bool isOffline = false;

                lock (_onlineUsersLock)
                {
                    if (_onlineUsers.TryGetValue(userId, out var connections))
                    {
                        connections.Remove(Context.ConnectionId);

                        // Nếu không còn connection nào thì user này offline thật sự
                        if (connections.Count == 0)
                        {
                            _onlineUsers.TryRemove(userId, out _);
                            isOffline = true;
                        }
                    }
                }

                Console.WriteLine($"🔴 User disconnected: {userId} | ConnectionId: {Context.ConnectionId}");

                if (isOffline)
                {
                    // Báo cho các client khác biết user này vừa offline
                    await Clients.Others.SendAsync("UserOffline", userId);
                }
            }

            await base.OnDisconnectedAsync(exception);
        }

        // Cổng cho Flutter hỏi thăm tình trạng lúc mới mở khung chat
        public bool IsUserOnline(string userId)
        {
            if (string.IsNullOrWhiteSpace(userId)) return false;

            lock (_onlineUsersLock)
            {
                return _onlineUsers.TryGetValue(userId, out var connections)
                    && connections.Count > 0;
            }
        }

        // ==========================================
        // CÁC HÀM CÒN LẠI GIỮ NGUYÊN HOÀN TOÀN
        // ==========================================

        public async Task JoinConversation(string conversationId)
        {
            var currentUserId = Context.UserIdentifier;
            if (string.IsNullOrEmpty(currentUserId)) throw new HubException("Token không hợp lệ.");
            if (!Guid.TryParse(conversationId, out var conversationGuid)) throw new HubException("ConversationId không hợp lệ.");

            await Groups.AddToGroupAsync(Context.ConnectionId, conversationGuid.ToString());
        }

        public async Task SendMessage(string conversationId, string content, string type, string metadata)
        {
            try 
            {
                var currentUserId = Context.UserIdentifier;
                if (string.IsNullOrEmpty(currentUserId)) throw new HubException("Token không hợp lệ.");
                if (!Guid.TryParse(conversationId, out var conversationGuid)) throw new HubException("ConversationId không hợp lệ.");

                string cacheKey = $"IsMember_{conversationId}_{currentUserId}";
                
                if (!_cache.TryGetValue(cacheKey, out bool isMember))
                {
                    isMember = await _db.Participants.AnyAsync(p => 
                        p.ConversationId == conversationGuid && p.UserId == Guid.Parse(currentUserId)
                    );

                    if (isMember)
                    {
                        _cache.Set(cacheKey, true, TimeSpan.FromHours(1));
                    }
                }

                if (!isMember) throw new HubException("Bạn không thuộc phòng chat này.");

                var encrypted = _crypto.Encrypt(content);

                JsonDocument? metaDoc = null;
                if (!string.IsNullOrWhiteSpace(metadata))
                {
                    try { metaDoc = JsonDocument.Parse(metadata); } catch { /* Bỏ qua nếu lỗi format */ }
                }

                var message = new Message
                {
                    ConversationId = conversationGuid,
                    SenderId = Guid.Parse(currentUserId),
                    Ciphertext = encrypted.Ciphertext,
                    Nonce = encrypted.Nonce,
                    Tag = encrypted.Tag,
                    KeyId = _crypto.CurrentKeyId,
                    Type = string.IsNullOrWhiteSpace(type) ? "text" : type,
                    Metadata = metaDoc, 
                    CreatedAt = DateTime.UtcNow,
                    IsDeleted = false
                };

                await Clients.Group(conversationId).SendAsync("ReceiveMessage", new
                {
                    id = message.Id.ToString(),
                    conversationId = conversationId,
                    senderId = currentUserId,
                    content = content,
                    type = message.Type,
                    metadata = metadata, 
                    createdAt = message.CreatedAt
                });

                await _queue.EnqueueAsync(message);
            }
            catch (Exception ex)
            {
                throw new HubException($"Lỗi C# nội bộ: {ex.Message}");
            }
        }

        public async Task SendWebRTCSignal(string conversationId, string type, string content)
        {
            var currentUserId = Context.UserIdentifier;
            if (string.IsNullOrEmpty(currentUserId)) throw new HubException("Token không hợp lệ.");

            var userGuid = Guid.Parse(currentUserId);
            var caller = await _db.Users.FindAsync(userGuid);
            
            string callerName = caller?.Fullname ?? "Người gọi";
            string callerAvatar = caller?.Avatarurl ?? "";

            await Clients.GroupExcept(conversationId, Context.ConnectionId)
                         .SendAsync("ReceiveWebRTCSignal", conversationId, type, content, callerName, callerAvatar);
        }
        
        public async Task EndCallSignal(string conversationId)
        {
            await Clients.GroupExcept(conversationId, Context.ConnectionId)
                         .SendAsync("ReceiveWebRTCSignal", conversationId, "end", "Ended", "", "");
        }
    }
}