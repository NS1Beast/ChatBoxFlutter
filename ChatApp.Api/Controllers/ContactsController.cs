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

        // ==========================================
        // 1. TÌM KIẾM NGƯỜI DÙNG THEO EMAIL
        // GET: api/contacts/search?email=abc@gmail.com
        // ==========================================
        [HttpGet("search")]
        public async Task<IActionResult> SearchUser([FromQuery] string email, [FromQuery] Guid currentUserId)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == email);
            if (user == null) return NotFound(new { message = "Không tìm thấy người dùng nào với Email này!" });

            // Kiểm tra xem 2 người đã là bạn bè chưa (Chỉ cần check 1 chiều là đủ biết)
            bool isFriend = await _context.Contacts.AnyAsync(c => c.Userid == currentUserId && c.Friendid == user.Id);

            return Ok(new
            {
                id = user.Id,
                email = user.Email,
                fullName = user.Fullname,
                avatarUrl = user.Avatarurl,
                bio = user.Bio,
                isFriend = isFriend
            });
        }

        // ==========================================
        // 2. KẾT BẠN (XỬ LÝ 2 CHIỀU)
        // POST: api/contacts/add
        // ==========================================
        [HttpPost("add")]
        public async Task<IActionResult> AddFriend([FromBody] AddContactRequest request)
        {
            // 🎯 Lấy cả 2 chiều của mối quan hệ
            var contactAtoB = await _context.Contacts
                .FirstOrDefaultAsync(c => c.Userid == request.UserId && c.Friendid == request.FriendId);
                
            var contactBtoA = await _context.Contacts
                .FirstOrDefaultAsync(c => c.Userid == request.FriendId && c.Friendid == request.UserId);

            // NẾU ĐÃ CÓ BẤT KỲ CHIỀU NÀO -> HỦY KẾT BẠN (XÓA SẠCH)
            if (contactAtoB != null || contactBtoA != null)
            {
                if (contactAtoB != null) _context.Contacts.Remove(contactAtoB);
                if (contactBtoA != null) _context.Contacts.Remove(contactBtoA);
                
                await _context.SaveChangesAsync();
                return Ok(new { message = "Đã hủy kết bạn", isFriend = false });
            }

            // NẾU CHƯA CÓ -> THÊM KẾT BẠN 2 CHIỀU
            var newContactAtoB = new Contact
            {
                Userid = request.UserId,
                Friendid = request.FriendId,
                Status = "accepted", 
                Createdat = DateTime.UtcNow
            };

            var newContactBtoA = new Contact
            {
                Userid = request.FriendId,
                Friendid = request.UserId,
                Status = "accepted", 
                Createdat = DateTime.UtcNow
            };

            _context.Contacts.AddRange(newContactAtoB, newContactBtoA);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đã thêm bạn bè thành công", isFriend = true });
        }

        // ==========================================
        // 3. LẤY DANH SÁCH BẠN BÈ ĐỂ HIỂN THỊ
        // GET: api/contacts/list/{userId}
        // ==========================================
        [HttpGet("list/{userId}")]
        public async Task<IActionResult> GetFriendsList(Guid userId)
        {
            var friends = await _context.Contacts
                .Where(c => c.Userid == userId)
                .Select(c => new
                {
                    // Lưu ý: C# lấy thông tin thông qua Navigation Property 'Friend'
                    id = c.Friend.Id,
                    name = c.Friend.Fullname,
                    avatarUrl = c.Friend.Avatarurl,
                    bio = c.Friend.Bio
                }).ToListAsync();

            return Ok(friends);
        }
    }

    public class AddContactRequest
    {
        public Guid UserId { get; set; }
        public Guid FriendId { get; set; }
    }
}