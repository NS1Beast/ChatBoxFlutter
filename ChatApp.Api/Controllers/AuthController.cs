using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Isopoh.Cryptography.Argon2;
using ChatApp.Api.Models;

namespace ChatApp.Api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly ChatDbContext _context;
        private readonly IConfiguration _configuration;

        public AuthController(ChatDbContext context, IConfiguration configuration)
        {
            _context = context;
            _configuration = configuration;
        }

        // ==========================================
        // 1. MODELS DỮ LIỆU
        // ==========================================
        public class LoginRequest
        {
            public string Email { get; set; } = string.Empty;
            public string Password { get; set; } = string.Empty;
        }

        public class RegisterRequest
        {
            public string FullName { get; set; } = string.Empty;
            public string Email { get; set; } = string.Empty;
            public string Password { get; set; } = string.Empty;
        }

        // ==========================================
        // 2. API ĐĂNG KÝ
        // POST: api/auth/register
        // ==========================================
        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterRequest request)
        {
            var existingUser = await _context.Users
                .FirstOrDefaultAsync(u => u.Email == request.Email);

            if (existingUser != null)
            {
                return BadRequest(new { message = "Email này đã được sử dụng!" });
            }

            string secureHash = Argon2.Hash(request.Password);

            var newUser = new User
            {
                Email = request.Email,
                Passwordhash = secureHash,
                Fullname = request.FullName,
                Createdat = DateTime.UtcNow
            };

            _context.Users.Add(newUser);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Tạo tài khoản thành công!" });
        }

        // ==========================================
        // 3. API ĐĂNG NHẬP
        // POST: api/auth/login
        // ==========================================
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Email == request.Email);

            if (user == null)
            {
                return BadRequest(new { message = "Email hoặc mật khẩu không chính xác!" });
            }

            bool isPasswordValid = Argon2.Verify(user.Passwordhash, request.Password);

            if (!isPasswordValid)
            {
                return BadRequest(new { message = "Email hoặc mật khẩu không chính xác!" });
            }

            var token = GenerateJwtToken(user);

            return Ok(new
            {
                token,
                user = new
                {
                    id = user.Id,
                    email = user.Email,
                    fullName = user.Fullname,
                    avatarUrl = user.Avatarurl,
                    bio = user.Bio
                }
            });
        }

        // ==========================================
        // 4. API DÀNH CHO DESKTOP: GỌI GOOGLE
        // Flutter Desktop mở link:
        // GET api/auth/desktop-login/google
        // ==========================================
        [HttpGet("desktop-login/{provider}")]
        public IActionResult DesktopLogin(string provider)
        {
            // Đã xóa hoàn toàn Facebook khỏi bộ lọc
            string scheme = provider.ToLower() switch
            {
                "google" => "Google",
                _ => string.Empty
            };

            if (string.IsNullOrEmpty(scheme))
            {
                return BadRequest(new
                {
                    message = "Provider không hợp lệ. Hệ thống hiện chỉ hỗ trợ đăng nhập bằng Google."
                });
            }

            var redirectUrl = Url.Action(
                nameof(ExternalLoginCallback),
                "Auth",
                new { returnUrl = "prochat://login" },
                Request.Scheme
            );

            var properties = new AuthenticationProperties
            {
                RedirectUri = redirectUrl
            };

            return Challenge(properties, scheme);
        }

        // ==========================================
        // 5. API HỨNG KẾT QUẢ VÀ ĐÁ NGƯỢC VỀ FLUTTER DESKTOP
        // GET api/auth/callback
        // ==========================================
        [HttpGet("callback")]
        public async Task<IActionResult> ExternalLoginCallback(
            string returnUrl = "prochat://login")
        {
            var authenticateResult = await HttpContext.AuthenticateAsync(
                CookieAuthenticationDefaults.AuthenticationScheme
            );

            if (!authenticateResult.Succeeded || authenticateResult.Principal == null)
            {
                return BadRequest("Đăng nhập mạng xã hội thất bại!");
            }

            var email = authenticateResult.Principal
                .FindFirst(ClaimTypes.Email)?.Value;

            var name = authenticateResult.Principal
                .FindFirst(ClaimTypes.Name)?.Value;

            if (string.IsNullOrEmpty(email))
            {
                return BadRequest("Không lấy được Email từ tài khoản mạng xã hội!");
            }

            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Email == email);

            if (user == null)
            {
                user = new User
                {
                    Email = email,
                    Fullname = name ?? "Người dùng mới",
                    Passwordhash = string.Empty,
                    Createdat = DateTime.UtcNow
                };

                _context.Users.Add(user);
                await _context.SaveChangesAsync();
            }

            var token = GenerateJwtToken(user);

            await HttpContext.SignOutAsync(
                CookieAuthenticationDefaults.AuthenticationScheme
            );

            return Redirect($"{returnUrl}?token={Uri.EscapeDataString(token)}");
        }

        // ==========================================
        // 6. HÀM TẠO JWT TOKEN
        // ==========================================
        private string GenerateJwtToken(User user)
        {
            var jwtSettings = _configuration.GetSection("Jwt");
            var key = Encoding.ASCII.GetBytes(jwtSettings["Key"]!);

            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(new[]
                {
                    new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                    new Claim(ClaimTypes.Email, user.Email),
                    new Claim(ClaimTypes.Name, user.Fullname)
                }),

                Expires = DateTime.UtcNow.AddDays(7),
                Issuer = jwtSettings["Issuer"],
                Audience = jwtSettings["Audience"],

                SigningCredentials = new SigningCredentials(
                    new SymmetricSecurityKey(key),
                    SecurityAlgorithms.HmacSha256Signature
                )
            };

            var tokenHandler = new JwtSecurityTokenHandler();
            var token = tokenHandler.CreateToken(tokenDescriptor);

            return tokenHandler.WriteToken(token);
        }
    }
}