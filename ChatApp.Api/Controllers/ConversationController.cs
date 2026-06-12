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

        // ==========================================
        // 1. LẤY HOẶC TẠO CHAT 1-1 (Giữ nguyên)
        // ==========================================
        [HttpPost("get-or-create")]
        public async Task<IActionResult> GetOrCreateConversation([FromBody] CreateConversationRequest request)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var currentUserId))
                return Unauthorized(new { message = "Token không hợp lệ hoặc đã hết hạn." });

            if (currentUserId == request.FriendId)
                return BadRequest(new { message = "Bạn không thể tạo cuộc trò chuyện với chính mình." });

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

        // ==========================================
        // 2. LẤY LỊCH SỬ TIN NHẮN ĐỂ SYNC (Giữ nguyên)
        // ==========================================
        [HttpGet("{conversationId}/messages")] 
        public async Task<IActionResult> GetMessages(Guid conversationId, [FromQuery] string? since)
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

                // 1. Dựng khung Query cơ bản
                var query = _db.Messages
                    .AsNoTracking()
                    .Where(m => m.ConversationId == conversationId && !m.IsDeleted);

                // 2. 🎯 CƠ CHẾ SYNC: Lọc những tin nhắn MỚI HƠN thời gian Flutter gửi lên
                if (!string.IsNullOrWhiteSpace(since) && DateTime.TryParse(since, out DateTime sinceDate))
                {
                    var utcSinceDate = sinceDate.ToUniversalTime();
                    query = query.Where(m => m.CreatedAt > utcSinceDate);
                }

                // 3. Thực thi lấy dữ liệu từ DB
                var messagesList = await query
                    .OrderBy(m => m.CreatedAt)
                    .ToListAsync();

                // 4. Giải mã và đóng gói trả về JSON
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
                        metadata = m.Metadata, // 🎯 QUAN TRỌNG: Trả về cục Metadata để Flutter giải mã ra Reply/Emoji
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

        // ==========================================
        // 🚀 3. TẠO NHÓM CHAT (Tự động cấp quyền Admin)
        // ==========================================
        public class CreateGroupRequest
        {
            public string GroupName { get; set; } = string.Empty;
            public List<Guid> MemberIds { get; set; } = new();
        }

        [HttpPost("group")]
        public async Task<IActionResult> CreateGroup([FromBody] CreateGroupRequest request)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var currentUserId))
                return Unauthorized();

            if (string.IsNullOrWhiteSpace(request.GroupName))
                return BadRequest(new { message = "Tên nhóm không được để trống." });

            using var transaction = await _db.Database.BeginTransactionAsync();
            try
            {
                var newGroup = new Conversation { IsGroup = true, GroupName = request.GroupName, CreatedAt = DateTime.UtcNow };
                await _db.Conversations.AddAsync(newGroup);
                await _db.SaveChangesAsync();

                // 🎯 Người tạo nhóm Auto thành Trưởng Nhóm (admin)
                var participants = new List<Participant>
                {
                    new Participant { ConversationId = newGroup.Id, UserId = currentUserId, Role = "admin", JoinedAt = DateTime.UtcNow }
                };

                // Thêm các thành viên được chọn vào (Loại bỏ ID trùng và ID của chính mình)
                foreach (var memberId in request.MemberIds.Distinct())
                {
                    if (memberId != currentUserId)
                    {
                        participants.Add(new Participant { ConversationId = newGroup.Id, UserId = memberId, Role = "member", JoinedAt = DateTime.UtcNow });
                    }
                }

                await _db.Participants.AddRangeAsync(participants);
                await _db.SaveChangesAsync();
                await transaction.CommitAsync();

                return Ok(new { conversationId = newGroup.Id, message = "Tạo nhóm thành công!" });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, new { message = "Lỗi tạo nhóm.", error = ex.Message });
            }
        }

        // ==========================================
        // 🚀 4. THÊM THÀNH VIÊN VÀO NHÓM
        // ==========================================
        [HttpPost("{conversationId}/members")]
        public async Task<IActionResult> AddMembersToGroup(Guid conversationId, [FromBody] List<Guid> newMemberIds)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var currentUserId))
                return Unauthorized();

            // Kiểm tra xem người đang request có nằm trong nhóm này không
            var isMember = await _db.Participants.AnyAsync(p => p.ConversationId == conversationId && p.UserId == currentUserId);
            if (!isMember) return StatusCode(403, new { message = "Bạn không thuộc nhóm này." });

            var group = await _db.Conversations.FindAsync(conversationId);
            if (group == null || group.IsGroup == false) return BadRequest(new { message = "Đây không phải là nhóm chat." });

            // Lọc ra những người ĐÃ CÓ trong nhóm
            var existingMembers = await _db.Participants.Where(p => p.ConversationId == conversationId).Select(p => p.UserId).ToListAsync();
            
            // Những người thực sự MỚI
            var toAdd = newMemberIds.Except(existingMembers).Distinct().ToList();

            if (!toAdd.Any()) return BadRequest(new { message = "Các thành viên này đã có trong nhóm rồi." });

            var newParticipants = toAdd.Select(id => new Participant 
            {
                ConversationId = conversationId, UserId = id, Role = "member", JoinedAt = DateTime.UtcNow
            });

            await _db.Participants.AddRangeAsync(newParticipants);
            await _db.SaveChangesAsync();

            return Ok(new { message = $"Đã thêm {toAdd.Count} thành viên thành công!" });
        }

        // ==========================================
        // 🚀 5. KICK THÀNH VIÊN (Chỉ Admin mới làm được)
        // ==========================================
        [HttpDelete("{conversationId}/members/{userIdToKick}")]
        public async Task<IActionResult> KickMember(Guid conversationId, Guid userIdToKick)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var currentUserId))
                return Unauthorized();

            // 🎯 Lấy Role của user đang thao tác
            var currentUser = await _db.Participants.FirstOrDefaultAsync(p => p.ConversationId == conversationId && p.UserId == currentUserId);
            
            if (currentUser == null) return NotFound(new { message = "Bạn không có trong nhóm này." });
            
            // 🎯 Check quyền: Nếu không phải Admin thì từ chối!
            if (currentUser.Role != "admin")
                return StatusCode(403, new { message = "Chỉ trưởng nhóm (admin) mới có quyền mời người khác ra khỏi nhóm." });

            if (currentUserId == userIdToKick)
                return BadRequest(new { message = "Bạn không thể tự sút chính mình. Vui lòng dùng tính năng Rời Nhóm." });

            var targetUser = await _db.Participants.FirstOrDefaultAsync(p => p.ConversationId == conversationId && p.UserId == userIdToKick);
            if (targetUser == null) return NotFound(new { message = "Thành viên này không tồn tại trong nhóm." });

            _db.Participants.Remove(targetUser);
            await _db.SaveChangesAsync();

            return Ok(new { message = "Đã mời thành viên ra khỏi nhóm." });
        }
        // ==========================================
        // 🚀 6. LẤY DANH SÁCH THÀNH VIÊN TRONG NHÓM
        // ==========================================
        [HttpGet("{conversationId}/members")]
        public async Task<IActionResult> GetGroupMembers(Guid conversationId)
        {
            var members = await _db.Participants
                .Where(p => p.ConversationId == conversationId)
                .Include(p => p.User) // Join bảng để lấy Tên và Avatar
                .Select(p => new
                {
                    userId = p.UserId,
                    fullName = p.User.Fullname,
                    avatarUrl = p.User.Avatarurl,
                    role = p.Role,
                    joinedAt = p.JoinedAt
                })
                .ToListAsync();

            return Ok(members);
        }
        
        // ==========================================
        // 🚀 7. LẤY DANH SÁCH NHÓM MÌNH ĐANG THAM GIA
        // ==========================================
        [HttpGet("my-groups")]
        public async Task<IActionResult> GetMyGroups()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var currentUserId))
                return Unauthorized();

            // 🎯 ĐÃ SỬA: Viết Query trực tiếp, bỏ qua Include để tránh lỗi Model
            var groups = await _db.Conversations
                .Where(c => c.IsGroup == true && _db.Participants.Any(p => p.ConversationId == c.Id && p.UserId == currentUserId))
                .Select(c => new {
                    id = c.Id,
                    groupName = c.GroupName,
                    groupAvatarUrl = c.GroupAvatarUrl,
                    myRole = _db.Participants.FirstOrDefault(p => p.ConversationId == c.Id && p.UserId == currentUserId).Role
                })
                .ToListAsync();

            return Ok(groups);
        }
    }
}