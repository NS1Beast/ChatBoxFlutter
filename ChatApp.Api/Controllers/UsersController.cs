using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ChatApp.Api.Models;

namespace ChatApp.Api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class UsersController : ControllerBase
    {
        private readonly ChatDbContext _context;

        public UsersController(ChatDbContext context)
        {
            _context = context;
        }

        // Cập nhật ảnh đại diện của người dùng
        [HttpPost("update-avatar")]
        public async Task<IActionResult> UpdateAvatar([FromBody] UpdateImageRequest request)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == request.UserId);

            if (user == null)
                return NotFound(new { message = "Không tìm thấy User" });

            user.Avatarurl = request.ImageBase64;

            await _context.SaveChangesAsync();

            return Ok(new { message = "Cập nhật Avatar thành công!" });
        }

        // Lấy thông tin hồ sơ người dùng theo id
        [HttpGet("profile/{id}")]
        public async Task<IActionResult> GetProfile(Guid id)
        {
            var user = await _context.Users.FindAsync(id);

            if (user == null)
                return NotFound();

            return Ok(new
            {
                fullname = user.Fullname,
                email = user.Email,
                avatar = user.Avatarurl,
                cover = user.Coverurl
            });
        }

        // Cập nhật ảnh bìa của người dùng
        [HttpPost("update-cover")]
        public async Task<IActionResult> UpdateCover([FromBody] UpdateImageRequest request)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == request.UserId);

            if (user == null)
                return NotFound(new { message = "Không tìm thấy User" });

            user.Coverurl = request.ImageBase64;

            await _context.SaveChangesAsync();

            return Ok(new { message = "Cập nhật Background thành công!" });
        }

        // Model nhận dữ liệu ảnh dạng Base64 từ client
        public class UpdateImageRequest
        {
            public Guid UserId { get; set; }
            public string ImageBase64 { get; set; } = string.Empty;
        }
    }
}