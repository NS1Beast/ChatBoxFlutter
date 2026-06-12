using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ChatApp.Api.Models;

namespace ChatApp.Api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ContactsController : ControllerBase
    {
        private readonly ChatDbContext _context;

        public ContactsController(ChatDbContext context)
        {
            _context = context;
        }

        // Tìm người dùng theo email và trả về trạng thái quan hệ với tài khoản hiện tại
        [HttpGet("search")]
        public async Task<IActionResult> SearchUser([FromQuery] string email, [FromQuery] Guid currentUserId)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == email);

            if (user == null)
                return NotFound(new { message = "Không tìm thấy người dùng nào với Email này!" });

            if (user.Id == currentUserId)
                return BadRequest(new { message = "Bạn không thể tìm kiếm chính mình!" });

            var contactAtoB = await _context.Contacts
                .FirstOrDefaultAsync(c => c.Userid == currentUserId && c.Friendid == user.Id);

            var contactBtoA = await _context.Contacts
                .FirstOrDefaultAsync(c => c.Userid == user.Id && c.Friendid == currentUserId);

            string relationStatus = "none";

            if (contactAtoB != null && contactAtoB.Status == "accepted")
            {
                relationStatus = "friend";
            }
            else if (contactAtoB != null && contactAtoB.Status == "pending")
            {
                relationStatus = "pending";
            }
            else if (contactBtoA != null && contactBtoA.Status == "pending")
            {
                relationStatus = "awaiting";
            }

            return Ok(new
            {
                id = user.Id,
                email = user.Email,
                fullName = user.Fullname,
                avatarUrl = user.Avatarurl,
                coverUrl = user.Coverurl,
                bio = user.Bio,
                relationStatus,
                isFriend = relationStatus == "friend"
            });
        }

        // Gửi, hủy, chấp nhận hoặc hủy kết bạn tùy theo trạng thái hiện tại
        [HttpPost("add")]
        public async Task<IActionResult> AddFriend([FromBody] AddContactRequest request)
        {
            var contactAtoB = await _context.Contacts
                .FirstOrDefaultAsync(c => c.Userid == request.UserId && c.Friendid == request.FriendId);

            var contactBtoA = await _context.Contacts
                .FirstOrDefaultAsync(c => c.Userid == request.FriendId && c.Friendid == request.UserId);

            // Hủy kết bạn nếu hai người đã là bạn bè
            if (contactAtoB != null && contactAtoB.Status == "accepted")
            {
                _context.Contacts.Remove(contactAtoB);

                if (contactBtoA != null)
                    _context.Contacts.Remove(contactBtoA);

                await _context.SaveChangesAsync();

                return Ok(new { message = "Đã hủy kết bạn", status = "none" });
            }

            // Thu hồi lời mời nếu người dùng đã gửi yêu cầu trước đó
            if (contactAtoB != null && contactAtoB.Status == "pending")
            {
                _context.Contacts.Remove(contactAtoB);
                await _context.SaveChangesAsync();

                return Ok(new { message = "Đã thu hồi yêu cầu kết bạn", status = "none" });
            }

            // Chấp nhận lời mời nếu người kia đã gửi yêu cầu kết bạn
            if (contactBtoA != null && contactBtoA.Status == "pending")
            {
                contactBtoA.Status = "accepted";

                var newContactAtoB = new Contact
                {
                    Userid = request.UserId,
                    Friendid = request.FriendId,
                    Status = "accepted",
                    Createdat = DateTime.UtcNow
                };

                _context.Contacts.Add(newContactAtoB);
                await _context.SaveChangesAsync();

                return Ok(new { message = "Đã chấp nhận kết bạn", status = "friend" });
            }

            // Tạo lời mời kết bạn mới nếu chưa có quan hệ trước đó
            var pendingContact = new Contact
            {
                Userid = request.UserId,
                Friendid = request.FriendId,
                Status = "pending",
                Createdat = DateTime.UtcNow
            };

            _context.Contacts.Add(pendingContact);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đã gửi yêu cầu kết bạn", status = "pending" });
        }

        // Lấy danh sách bạn bè đã được chấp nhận
        [HttpGet("list/{userId}")]
        public async Task<IActionResult> GetFriendsList(Guid userId)
        {
            var friends = await _context.Contacts
                .Where(c => c.Userid == userId && c.Status == "accepted")
                .Select(c => new
                {
                    id = c.Friend.Id,
                    name = c.Friend.Fullname,
                    avatarUrl = c.Friend.Avatarurl,
                    coverUrl = c.Friend.Coverurl,
                    bio = c.Friend.Bio
                })
                .ToListAsync();

            return Ok(friends);
        }
    }

    public class AddContactRequest
    {
        public Guid UserId { get; set; }
        public Guid FriendId { get; set; }
    }
}