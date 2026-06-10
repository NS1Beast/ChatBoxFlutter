using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory; // 🎯 IMPORT CACHE
using System.Security.Claims;
using ChatApp.Api.Models;
using ChatApp.Api.Services;

namespace ChatApp.Api.Hubs
{
    [Authorize]
    public class ChatHub : Hub
    {
        private readonly ChatDbContext _db;
        private readonly EncryptionService _crypto;
        private readonly IMemoryCache _cache; // 🎯 CHIÊU 1: RAM CACHE
        private readonly MessageQueue _queue; // 🎯 CHIÊU 2: HÀNG ĐỢI

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

            // Kéo user vào phòng
            await Groups.AddToGroupAsync(Context.ConnectionId, conversationGuid.ToString());
        }

        public async Task SendMessage(string conversationId, string content, string type)
        {
            var currentUserId = Context.UserIdentifier;
            if (string.IsNullOrEmpty(currentUserId)) throw new HubException("Token không hợp lệ.");
            if (!Guid.TryParse(conversationId, out var conversationGuid)) throw new HubException("ConversationId không hợp lệ.");

            // ==========================================
            // 🎯 CHIÊU 1: DÙNG RAM ĐỂ NHỚ QUYỀN (CACHING)
            // ==========================================
            string cacheKey = $"IsMember_{conversationId}_{currentUserId}";
            
            // Hỏi RAM xem ông này có quyền chưa?
            if (!_cache.TryGetValue(cacheKey, out bool isMember))
            {
                // Nếu RAM chưa biết, mới phải lội xuống Database hỏi
                isMember = await _db.Participants.AnyAsync(p => 
                    p.ConversationId == conversationGuid && p.UserId == Guid.Parse(currentUserId)
                );

                if (isMember)
                {
                    // Lưu kết quả vào RAM trong 1 tiếng. Lần sau gửi tin nhắn mất 0s để check!
                    _cache.Set(cacheKey, true, TimeSpan.FromHours(1));
                }
            }

            if (!isMember) throw new HubException("Bạn không thuộc phòng chat này.");

            // Mã hóa
            var encrypted = _crypto.Encrypt(content);

            var message = new Message
            {
                ConversationId = conversationGuid,
                SenderId = Guid.Parse(currentUserId),
                Ciphertext = encrypted.Ciphertext,
                Nonce = encrypted.Nonce,
                Tag = encrypted.Tag,
                KeyId = _crypto.CurrentKeyId,
                Type = string.IsNullOrWhiteSpace(type) ? "text" : type,
                CreatedAt = DateTime.UtcNow,
                IsDeleted = false
            };

            // ==========================================
            // 🎯 CHIÊU 2: FIRE-AND-FORGET (BẮN TỐC ĐỘ BÀN THỜ)
            // ==========================================
            // 1. Bắn tin nhắn về thẳng các Client ngay tắp lự (KHÔNG CHỜ DATABASE)
            await Clients.Group(conversationId).SendAsync("ReceiveMessage", new
            {
                id = message.Id.ToString(),
                conversationId = conversationId,
                senderId = currentUserId,
                content = content,
                type = message.Type,
                createdAt = message.CreatedAt
            });

            // 2. Quăng gói hàng vào Băng chuyền để BackgroundService tự lôi xuống DB cất từ từ
            await _queue.EnqueueAsync(message);
        }
    }
}