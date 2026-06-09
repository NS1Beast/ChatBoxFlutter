using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using ChatApp.Api.Models; 
using ChatApp.Api.Services; 

namespace ChatApp.Api.Controllers 
{
    [Authorize] 
    [ApiController]
    [Route("api/[controller]")]
    public class ConversationsController : ControllerBase
    {
        private readonly ChatDbContext _db; 
        private readonly EncryptionService _crypto;

        public ConversationsController(ChatDbContext db, EncryptionService crypto) 
        {
            _db = db;
            _crypto = crypto;
        }

        public class CreateConversationRequest
        {
            public Guid FriendId { get; set; }
        }

        [HttpPost("get-or-create")]
        public async Task<IActionResult> GetOrCreateConversation([FromBody] CreateConversationRequest request)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var currentUserId))
                return Unauthorized(new { message = "Token không hợp lệ hoặc đã hết hạn." });

            if (currentUserId == request.FriendId)
                return BadRequest(new { message = "Bạn không thể tạo cuộc trò chuyện với chính mình." });

            // 🎯 Giữ nguyên lệnh OrderBy để lấy gốc rễ phòng chat
            var existingConversationId = await _db.Conversations
                .Where(c => c.IsGroup == false)
                .Where(c => _db.Participants.Any(p => p.ConversationId == c.Id && p.UserId == currentUserId))
                .Where(c => _db.Participants.Any(p => p.ConversationId == c.Id && p.UserId == request.FriendId))
                .OrderBy(c => c.CreatedAt) 
                .Select(c => c.Id)
                .FirstOrDefaultAsync();

            if (existingConversationId != Guid.Empty)
                return Ok(new { conversationId = existingConversationId });

            var friendExists = await _db.Users.AnyAsync(u => u.Id == request.FriendId);
            if (!friendExists) return NotFound(new { message = "Không tìm thấy người dùng này trên hệ thống." });

            using var transaction = await _db.Database.BeginTransactionAsync();
            try
            {
                var newConversation = new Conversation { IsGroup = false, CreatedAt = DateTime.UtcNow };
                await _db.Conversations.AddAsync(newConversation);
                await _db.SaveChangesAsync(); 

                var p1 = new Participant { ConversationId = newConversation.Id, UserId = currentUserId, Role = "member", JoinedAt = DateTime.UtcNow };
                var p2 = new Participant { ConversationId = newConversation.Id, UserId = request.FriendId, Role = "member", JoinedAt = DateTime.UtcNow };

                await _db.Participants.AddRangeAsync(p1, p2);
                await _db.SaveChangesAsync();
                await transaction.CommitAsync();

                return Ok(new { conversationId = newConversation.Id });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, new { message = "Đã xảy ra lỗi khi tạo phòng chat.", error = ex.Message });
            }
        }

        // 🎯 ĐÃ FIX: Báo lỗi cực kỳ chi tiết, bọc try-catch
        [HttpGet("{conversationId}/messages")] // 🎯 ĐÃ SỬA: Xóa chữ ":guid" đi cho nó dễ chịu
        public async Task<IActionResult> GetMessages(Guid conversationId)
        {
            try
            {
                var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var currentUserId))
                    return Unauthorized(new { message = "Token không hợp lệ." });

                var isMember = await _db.Participants.AnyAsync(p => p.ConversationId == conversationId && p.UserId == currentUserId);

                if (!isMember)
                {
                    return StatusCode(403, new { 
                        message = "User hiện tại không thuộc conversation này.", 
                        conversationId, currentUserId 
                    });
                }

                var messagesList = await _db.Messages
                    .AsNoTracking()
                    .Where(m => m.ConversationId == conversationId && !m.IsDeleted)
                    .OrderBy(m => m.CreatedAt)
                    .ToListAsync();

                var result = messagesList.Select(m =>
                {
                    string decryptedContent = "[Tin nhắn bị lỗi hoặc định dạng cũ]";
                    try
                    {
                        decryptedContent = _crypto.Decrypt(m.Ciphertext, m.Nonce, m.Tag);
                    }
                    catch (Exception ex)
                    {
                        decryptedContent = $"[Không giải mã được tin nhắn: {ex.Message}]";
                    }

                    return new
                    {
                        id = m.Id,
                        senderId = m.SenderId,
                        content = decryptedContent,
                        type = m.Type,
                        createdAt = m.CreatedAt
                    };
                });

                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { 
                    message = "Lỗi server khi tải lịch sử chat.", 
                    error = ex.Message, 
                    inner = ex.InnerException?.Message 
                });
            }
        }
    }
}