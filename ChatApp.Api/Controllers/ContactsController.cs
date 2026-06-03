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
        // 1. TÌM KIẾM NGƯỜI DÙNG (CÓ TRẠNG THÁI QUAN HỆ)
        // ==========================================
        [HttpGet("search")]
        public async Task<IActionResult> SearchUser([FromQuery] string email, [FromQuery] Guid currentUserId)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == email);
            if (user == null) return NotFound(new { message = "Không tìm thấy người dùng nào với Email này!" });

            // 🎯 Lấy thông tin 2 chiều để xét trạng thái
            var contactAtoB = await _context.Contacts.FirstOrDefaultAsync(c => c.Userid == currentUserId && c.Friendid == user.Id);
            var contactBtoA = await _context.Contacts.FirstOrDefaultAsync(c => c.Userid == user.Id && c.Friendid == currentUserId);

            string relationStatus = "none";
            if (contactAtoB != null && contactAtoB.Status == "accepted") relationStatus = "friend";
            else if (contactAtoB != null && contactAtoB.Status == "pending") relationStatus = "pending"; // Mình đã gửi
            else if (contactBtoA != null && contactBtoA.Status == "pending") relationStatus = "awaiting"; // Họ gửi, mình đang chờ đồng ý

            return Ok(new
            {
                id = user.Id,
                email = user.Email,
                fullName = user.Fullname,
                avatarUrl = user.Avatarurl,
                coverUrl = user.Coverurl,
                bio = user.Bio,
                relationStatus = relationStatus, // 🎯 Trả về trạng thái thực tế
                isFriend = (relationStatus == "friend") // Giữ lại biến này phòng hờ code cũ
            });
        }

        // ==========================================
        // 2. KẾT BẠN (XỬ LÝ 4 TRẠNG THÁI)
        // ==========================================
        [HttpPost("add")]
        public async Task<IActionResult> AddFriend([FromBody] AddContactRequest request)
        {
            var contactAtoB = await _context.Contacts.FirstOrDefaultAsync(c => c.Userid == request.UserId && c.Friendid == request.FriendId);
            var contactBtoA = await _context.Contacts.FirstOrDefaultAsync(c => c.Userid == request.FriendId && c.Friendid == request.UserId);

            // TH1: ĐANG LÀ BẠN BÈ -> HỦY KẾT BẠN
            if (contactAtoB != null && contactAtoB.Status == "accepted")
            {
                _context.Contacts.Remove(contactAtoB);
                if (contactBtoA != null) _context.Contacts.Remove(contactBtoA);
                await _context.SaveChangesAsync();
                return Ok(new { message = "Đã hủy kết bạn", status = "none" });
            }

            // TH2: MÌNH ĐÃ GỬI YÊU CẦU TRƯỚC ĐÓ -> HỦY YÊU CẦU
            if (contactAtoB != null && contactAtoB.Status == "pending")
            {
                _context.Contacts.Remove(contactAtoB);
                await _context.SaveChangesAsync();
                return Ok(new { message = "Đã thu hồi yêu cầu kết bạn", status = "none" });
            }

            // TH3: NGƯỜI KIA ĐÃ GỬI YÊU CẦU -> MÌNH ĐỒNG Ý
            if (contactBtoA != null && contactBtoA.Status == "pending")
            {
                contactBtoA.Status = "accepted"; // Cập nhật chiều B -> A thành bạn
                
                // Thêm chiều A -> B thành bạn
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

            // TH4: CHƯA CÓ GÌ -> GỬI YÊU CẦU KẾT BẠN MỚI
            var pendingContact = new Contact
            {
                Userid = request.UserId,
                Friendid = request.FriendId,
                Status = "pending", // 🎯 Đã sửa thành Pending (Chờ xác nhận)
                Createdat = DateTime.UtcNow
            };
            _context.Contacts.Add(pendingContact);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đã gửi yêu cầu kết bạn", status = "pending" });
        }

        // ==========================================
        // 3. LẤY DANH SÁCH BẠN BÈ (CHỈ LẤY NGƯỜI ĐÃ ACCEPT)
        // ==========================================
        [HttpGet("list/{userId}")]
        public async Task<IActionResult> GetFriendsList(Guid userId)
        {
            // 🎯 Lọc chặt chẽ: Chỉ trả về những ai có Status = "accepted"
            var friends = await _context.Contacts
                .Where(c => c.Userid == userId && c.Status == "accepted")
                .Select(c => new
                {
                    id = c.Friend.Id,
                    name = c.Friend.Fullname,
                    avatarUrl = c.Friend.Avatarurl,
                    coverUrl = c.Friend.Coverurl,
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