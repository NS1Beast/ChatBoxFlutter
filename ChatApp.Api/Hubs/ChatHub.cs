using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
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

        public ChatHub(ChatDbContext db, EncryptionService crypto)
        {
            _db = db;
            _crypto = crypto;
        }

        public async Task JoinConversation(string conversationId)
        {
            var userIdClaim = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var currentUserId))
                throw new HubException("Token không hợp lệ.");

            if (!Guid.TryParse(conversationId, out var conversationGuid))
                throw new HubException("ConversationId không hợp lệ.");

            var isMember = await _db.Participants.AnyAsync(p =>
                p.ConversationId == conversationGuid && p.UserId == currentUserId
            );

            if (!isMember) throw new HubException("Bạn không thuộc phòng chat này.");

            await Groups.AddToGroupAsync(Context.ConnectionId, conversationGuid.ToString());
        }

        public async Task SendMessage(string conversationId, string content, string type)
        {
            var userIdClaim = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var currentUserId))
                throw new HubException("Token không hợp lệ.");

            if (!Guid.TryParse(conversationId, out var conversationGuid))
                throw new HubException("ConversationId không hợp lệ.");

            var isMember = await _db.Participants.AnyAsync(p =>
                p.ConversationId == conversationGuid && p.UserId == currentUserId
            );

            if (!isMember) throw new HubException("Bạn không thuộc phòng chat này.");

            // Mã hóa trước khi lưu
            var encrypted = _crypto.Encrypt(content);

            var message = new Message
            {
                ConversationId = conversationGuid,
                SenderId = currentUserId,
                Ciphertext = encrypted.Ciphertext,
                Nonce = encrypted.Nonce,
                Tag = encrypted.Tag,
                KeyId = _crypto.CurrentKeyId,
                Type = string.IsNullOrWhiteSpace(type) ? "text" : type,
                CreatedAt = DateTime.UtcNow,
                IsDeleted = false
            };

            _db.Messages.Add(message);
            await _db.SaveChangesAsync();

            // Broadcast cho toàn bộ những người trong phòng (kể cả người gửi)
            await Clients.Group(conversationGuid.ToString()).SendAsync("ReceiveMessage", new
            {
                id = message.Id.ToString(),
                conversationId = conversationGuid.ToString(),
                senderId = currentUserId.ToString(),
                content = content,
                type = message.Type,
                createdAt = message.CreatedAt
            });
        }
    }
}