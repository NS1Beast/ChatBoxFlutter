using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using ChatApp.Api.Models;
using ChatApp.Api.Services;
using System.Text.Json;
using System.Text.Json.Nodes;

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

        // Model tạo cuộc trò chuyện 1-1
        public class CreateConversationRequest
        {
            public Guid FriendId { get; set; }
        }

        // Lấy hoặc tạo cuộc trò chuyện 1-1 giữa người dùng hiện tại và bạn bè
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

            if (!friendExists)
                return NotFound(new { message = "Không tìm thấy người dùng này trên hệ thống." });

            using var transaction = await _db.Database.BeginTransactionAsync();

            try
            {
                var newConversation = new Conversation
                {
                    IsGroup = false,
                    CreatedAt = DateTime.UtcNow
                };

                await _db.Conversations.AddAsync(newConversation);
                await _db.SaveChangesAsync();

                var p1 = new Participant
                {
                    ConversationId = newConversation.Id,
                    UserId = currentUserId,
                    Role = "member",
                    JoinedAt = DateTime.UtcNow
                };

                var p2 = new Participant
                {
                    ConversationId = newConversation.Id,
                    UserId = request.FriendId,
                    Role = "member",
                    JoinedAt = DateTime.UtcNow
                };

                await _db.Participants.AddRangeAsync(p1, p2);
                await _db.SaveChangesAsync();
                await transaction.CommitAsync();

                return Ok(new { conversationId = newConversation.Id });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();

                return StatusCode(500, new
                {
                    message = "Đã xảy ra lỗi khi tạo phòng chat.",
                    error = ex.Message
                });
            }
        }

        // Lấy lịch sử tin nhắn của một cuộc trò chuyện để đồng bộ với client
        [HttpGet("{conversationId}/messages")]
        public async Task<IActionResult> GetMessages(Guid conversationId, [FromQuery] string? since)
        {
            try
            {
                var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var currentUserId))
                    return Unauthorized(new { message = "Token không hợp lệ." });

                var isMember = await _db.Participants
                    .AnyAsync(p => p.ConversationId == conversationId && p.UserId == currentUserId);

                if (!isMember)
                    return StatusCode(403, new { message = "User hiện tại không thuộc conversation này." });

                var query = _db.Messages
                    .AsNoTracking()
                    .Where(m => m.ConversationId == conversationId && !m.IsDeleted);

                if (!string.IsNullOrWhiteSpace(since) && DateTime.TryParse(since, out DateTime sinceDate))
                {
                    var utcSinceDate = sinceDate.ToUniversalTime();
                    query = query.Where(m => m.CreatedAt > utcSinceDate);
                }

                var rawMessagesList = await query
                    .OrderBy(m => m.CreatedAt)
                    .ToListAsync();

                // Ẩn các tin nhắn đã bị xóa ở phía người dùng hiện tại
                var messagesList = rawMessagesList
                    .Where(m =>
                    {
                        if (m.Metadata == null)
                            return true;

                        string metaStr = m.Metadata.RootElement.GetRawText();

                        if (string.IsNullOrWhiteSpace(metaStr))
                            return true;

                        return !metaStr.Contains(currentUserId.ToString(), StringComparison.OrdinalIgnoreCase);
                    })
                    .ToList();

                // Giải mã nội dung tin nhắn trước khi trả về client
                var result = messagesList.Select(m =>
                {
                    string decryptedContent = "[Tin nhắn bị lỗi]";

                    if (m.Type == "revoked")
                    {
                        decryptedContent = "Tin nhắn đã được thu hồi";
                    }
                    else
                    {
                        try
                        {
                            decryptedContent = _crypto.Decrypt(m.Ciphertext, m.Nonce, m.Tag);
                        }
                        catch
                        {
                            decryptedContent = "[Không thể giải mã tin nhắn]";
                        }
                    }

                    return new
                    {
                        id = m.Id,
                        senderId = m.SenderId,
                        content = decryptedContent,
                        type = m.Type,
                        metadata = m.Metadata,
                        createdAt = m.CreatedAt
                    };
                });

                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    message = "Lỗi server khi tải lịch sử chat.",
                    error = ex.Message
                });
            }
        }

        // Model tạo nhóm chat
        public class CreateGroupRequest
        {
            public string GroupName { get; set; } = string.Empty;
            public List<Guid> MemberIds { get; set; } = new();
        }

        // Tạo nhóm chat mới và thêm các thành viên ban đầu
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
                var newGroup = new Conversation
                {
                    IsGroup = true,
                    GroupName = request.GroupName,
                    CreatedAt = DateTime.UtcNow
                };

                await _db.Conversations.AddAsync(newGroup);
                await _db.SaveChangesAsync();

                var participants = new List<Participant>
                {
                    new Participant
                    {
                        ConversationId = newGroup.Id,
                        UserId = currentUserId,
                        Role = "admin",
                        JoinedAt = DateTime.UtcNow
                    }
                };

                foreach (var memberId in request.MemberIds.Distinct())
                {
                    if (memberId != currentUserId)
                    {
                        participants.Add(new Participant
                        {
                            ConversationId = newGroup.Id,
                            UserId = memberId,
                            Role = "member",
                            JoinedAt = DateTime.UtcNow
                        });
                    }
                }

                await _db.Participants.AddRangeAsync(participants);
                await _db.SaveChangesAsync();
                await transaction.CommitAsync();

                return Ok(new
                {
                    conversationId = newGroup.Id,
                    message = "Tạo nhóm thành công!"
                });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();

                return StatusCode(500, new
                {
                    message = "Lỗi tạo nhóm.",
                    error = ex.Message
                });
            }
        }

        // Thêm thành viên mới vào nhóm chat
        [HttpPost("{conversationId}/members")]
        public async Task<IActionResult> AddMembersToGroup(Guid conversationId, [FromBody] List<Guid> newMemberIds)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var currentUserId))
                return Unauthorized();

            var isMember = await _db.Participants
                .AnyAsync(p => p.ConversationId == conversationId && p.UserId == currentUserId);

            if (!isMember)
                return StatusCode(403, new { message = "Bạn không thuộc nhóm này." });

            var group = await _db.Conversations.FindAsync(conversationId);

            if (group == null || group.IsGroup == false)
                return BadRequest(new { message = "Đây không phải là nhóm chat." });

            var existingMembers = await _db.Participants
                .Where(p => p.ConversationId == conversationId)
                .Select(p => p.UserId)
                .ToListAsync();

            var toAdd = newMemberIds
                .Except(existingMembers)
                .Distinct()
                .ToList();

            if (!toAdd.Any())
                return BadRequest(new { message = "Các thành viên này đã có trong nhóm rồi." });

            var newParticipants = toAdd.Select(id => new Participant
            {
                ConversationId = conversationId,
                UserId = id,
                Role = "member",
                JoinedAt = DateTime.UtcNow
            });

            await _db.Participants.AddRangeAsync(newParticipants);
            await _db.SaveChangesAsync();

            return Ok(new { message = $"Đã thêm {toAdd.Count} thành viên thành công!" });
        }

        // Mời một thành viên ra khỏi nhóm chat
        [HttpDelete("{conversationId}/members/{userIdToKick}")]
        public async Task<IActionResult> KickMember(Guid conversationId, Guid userIdToKick)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var currentUserId))
                return Unauthorized();

            var currentUser = await _db.Participants
                .FirstOrDefaultAsync(p => p.ConversationId == conversationId && p.UserId == currentUserId);

            if (currentUser == null)
                return NotFound(new { message = "Bạn không có trong nhóm này." });

            if (currentUser.Role != "admin")
                return StatusCode(403, new { message = "Chỉ trưởng nhóm (admin) mới có quyền mời người khác ra khỏi nhóm." });

            if (currentUserId == userIdToKick)
                return BadRequest(new { message = "Bạn không thể tự sút chính mình. Vui lòng dùng tính năng Rời Nhóm." });

            var targetUser = await _db.Participants
                .FirstOrDefaultAsync(p => p.ConversationId == conversationId && p.UserId == userIdToKick);

            if (targetUser == null)
                return NotFound(new { message = "Thành viên này không tồn tại trong nhóm." });

            _db.Participants.Remove(targetUser);
            await _db.SaveChangesAsync();

            return Ok(new { message = "Đã mời thành viên ra khỏi nhóm." });
        }

        // Lấy danh sách thành viên trong nhóm chat
        [HttpGet("{conversationId}/members")]
        public async Task<IActionResult> GetGroupMembers(Guid conversationId)
        {
            var members = await _db.Participants
                .Where(p => p.ConversationId == conversationId)
                .Include(p => p.User)
                .Select(p => new
                {
                    userId = p.UserId,
                    fullName = p.User != null ? p.User.Fullname : "Unknown",
                    avatarUrl = p.User != null ? p.User.Avatarurl : "",
                    role = p.Role,
                    joinedAt = p.JoinedAt
                })
                .ToListAsync();

            return Ok(members);
        }

        // Lấy danh sách nhóm mà người dùng hiện tại đang tham gia
        [HttpGet("my-groups")]
        public async Task<IActionResult> GetMyGroups()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var currentUserId))
                return Unauthorized();

            var groups = await _db.Conversations
                .Where(c => c.IsGroup == true && _db.Participants.Any(p => p.ConversationId == c.Id && p.UserId == currentUserId))
                .Select(c => new
                {
                    id = c.Id,
                    groupName = c.GroupName,
                    groupAvatarUrl = c.GroupAvatarUrl,
                    myRole = _db.Participants
                        .Where(p => p.ConversationId == c.Id && p.UserId == currentUserId)
                        .Select(p => p.Role)
                        .FirstOrDefault()
                })
                .ToListAsync();

            return Ok(groups);
        }

        // Thu hồi tin nhắn do người dùng hiện tại đã gửi
        [HttpPut("messages/{messageId}/revoke")]
        public async Task<IActionResult> RevokeMessage(Guid messageId)
        {
            var currentUserId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            var msg = await _db.Messages.FindAsync(messageId);

            if (msg == null)
                return NotFound(new { message = "Không tìm thấy tin nhắn." });

            if (msg.SenderId.ToString() != currentUserId)
                return BadRequest(new { message = "Bạn không thể thu hồi tin nhắn của người khác." });

            if ((DateTime.UtcNow - msg.CreatedAt).TotalMinutes > 5)
                return BadRequest(new { message = "Chỉ có thể thu hồi tin nhắn trong vòng 5 phút sau khi gửi." });

            msg.Type = "revoked";
            msg.Ciphertext = "";
            msg.Nonce = "";
            msg.Tag = "";

            await _db.SaveChangesAsync();

            return Ok(new { message = "Đã thu hồi tin nhắn thành công." });
        }

        // Xóa tin nhắn chỉ ở phía người dùng hiện tại
        [HttpPut("messages/{messageId}/delete-local")]
        public async Task<IActionResult> DeleteMessageForMe(Guid messageId)
        {
            var currentUserId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            var msg = await _db.Messages.FindAsync(messageId);

            if (msg == null)
                return NotFound();

            string metaString = msg.Metadata != null
                ? msg.Metadata.RootElement.GetRawText()
                : "";

            JsonObject metaNode;

            try
            {
                metaNode = string.IsNullOrWhiteSpace(metaString)
                    ? new JsonObject()
                    : JsonNode.Parse(metaString)?.AsObject() ?? new JsonObject();
            }
            catch
            {
                metaNode = new JsonObject();
            }

            JsonArray deletedForArray = metaNode.ContainsKey("deletedFor") && metaNode["deletedFor"] is JsonArray arr
                ? arr
                : new JsonArray();

            bool alreadyDeleted = false;

            foreach (var item in deletedForArray)
            {
                if (item?.ToString() == currentUserId)
                {
                    alreadyDeleted = true;
                    break;
                }
            }

            if (!alreadyDeleted)
            {
                deletedForArray.Add(currentUserId);
                metaNode["deletedFor"] = deletedForArray;

                msg.Metadata = JsonDocument.Parse(metaNode.ToJsonString());

                _db.Entry(msg).State = EntityState.Modified;
                await _db.SaveChangesAsync();
            }

            return Ok(new { message = "Đã xóa tin nhắn ở phía bạn." });
        }
    }
}