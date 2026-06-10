using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using System.Security.Claims;
using System.Text.Json; // 🎯 Cần thiết cho JsonDocument
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

        public ChatHub(ChatDbContext db, EncryptionService crypto, IMemoryCache cache, MessageQueue queue)
        {
            _db = db;
            _crypto = crypto;
            _cache = cache;
            _queue = queue;
        }

        public async Task JoinConversation(string conversationId)
        {
            var currentUserId = Context.UserIdentifier;
            if (string.IsNullOrEmpty(currentUserId)) throw new HubException("Token không hợp lệ.");
            if (!Guid.TryParse(conversationId, out var conversationGuid)) throw new HubException("ConversationId không hợp lệ.");

            await Groups.AddToGroupAsync(Context.ConnectionId, conversationGuid.ToString());
        }

        // 🎯 ĐÃ FIX: Khóa cứng 4 tham số (không dùng default parameter để tránh lú binding)
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

                // 🎯 Dịch chuỗi JSON an toàn
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
                    Metadata = metaDoc, // 🎯 Nạp vào DB
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
                    metadata = metadata, // 🎯 Bắn chuỗi JSON gốc về lại cho mọi người
                    createdAt = message.CreatedAt
                });

                await _queue.EnqueueAsync(message);
            }
            catch (Exception ex)
            {
                // 🎯 BẪY LỖI: Bắn thẳng lỗi nội tạng của C# về Flutter để dễ bề điều tra
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