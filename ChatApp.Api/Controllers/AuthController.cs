using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory; 
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using System.Net; 
using System.Net.Mail; 
using BCrypt.Net; 
using ChatApp.Api.Models;

namespace ChatApp.Api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly ChatDbContext _context;
        private readonly IConfiguration _configuration;
        private readonly IMemoryCache _cache; 

        public AuthController(ChatDbContext context, IConfiguration configuration, IMemoryCache cache)
        {
            _context = context;
            _configuration = configuration;
            _cache = cache;
        }

        // ==========================================
        // 1. MODELS DỮ LIỆU (ĐÃ TÁCH RIÊNG RẤT CHUẨN)
        // ==========================================
        public class LoginRequest { 
            public string Email { get; set; } = string.Empty; 
            public string Password { get; set; } = string.Empty; 
        }

        public class RegisterRequest { 
            public string FullName { get; set; } = string.Empty; 
            public string Email { get; set; } = string.Empty; 
            public string Password { get; set; } = string.Empty; 
            public string Otp { get; set; } = string.Empty; 
        }

        // 🎯 Tách riêng các Request cho Quên Mật Khẩu để chống lỗi Null Database
        public class ForgotPasswordRequest { 
            public string Email { get; set; } = string.Empty; 
        }

        public class VerifyOtpRequest { 
            public string Email { get; set; } = string.Empty; 
            public string Otp { get; set; } = string.Empty; 
        }

        public class ResetPasswordRequest { 
            public string Email { get; set; } = string.Empty; 
            public string Password { get; set; } = string.Empty; 
        }

        // ==========================================
        // 2A. BƯỚC 1: KIỂM TRA EMAIL VÀ GỬI MÃ OTP
        // ==========================================
        [HttpPost("send-otp")]
        public async Task<IActionResult> SendOtp([FromBody] RegisterRequest request)
        {
            if (request == null || string.IsNullOrEmpty(request.Email)) return BadRequest(new { message = "Email không hợp lệ!" });

            bool isExist = await _context.Users.AnyAsync(u => u.Email == request.Email);
            if (isExist) return BadRequest(new { message = "Email này đã được sử dụng cho tài khoản khác!" });

            string otpCode = new Random().Next(100000, 999999).ToString();
            _cache.Set($"OTP_{request.Email}", otpCode, TimeSpan.FromMinutes(3));

            try
            {
                await SendEmailAsync(request.Email, otpCode, "Mã xác thực đăng ký tài khoản");
                return Ok(new { message = "Đã gửi mã OTP thành công!" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi gửi mail: {ex.Message}" });
            }
        }

        // ==========================================
        // 2B. BƯỚC 2: XÁC THỰC MÃ OTP
        // ==========================================
        [HttpPost("verify-otp")]
        public IActionResult VerifyOtp([FromBody] RegisterRequest request)
        {
            if (request == null) return BadRequest(new { message = "Dữ liệu không hợp lệ!" });

            if (_cache.TryGetValue($"OTP_{request.Email}", out string? savedOtp))
            {
                if (savedOtp == request.Otp)
                {
                    _cache.Set($"VERIFIED_{request.Email}", true, TimeSpan.FromMinutes(10));
                    _cache.Remove($"OTP_{request.Email}");
                    return Ok(new { message = "Xác thực OTP thành công!" });
                }
                return BadRequest(new { message = "Mã OTP không chính xác!" });
            }

            return BadRequest(new { message = "Mã OTP đã hết hạn hoặc không tồn tại!" });
        }

        // ==========================================
        // 2C. BƯỚC 3: ĐĂNG KÝ CUỐI CÙNG 
        // ==========================================
        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterRequest request)
        {
            if (request == null) return BadRequest(new { message = "Dữ liệu không hợp lệ!" });

            if (!_cache.TryGetValue($"VERIFIED_{request.Email}", out bool isVerified) || !isVerified)
            {
                return BadRequest(new { message = "Vui lòng xác thực OTP trước khi tạo tài khoản!" });
            }

            string secureHash = BCrypt.Net.BCrypt.HashPassword(request.Password);

            var newUser = new User
            {
                Email = request.Email,
                Passwordhash = secureHash,
                Fullname = request.FullName,
                Createdat = DateTime.UtcNow,
                Settings = new UserSettings() 
            };

            _context.Users.Add(newUser);
            await _context.SaveChangesAsync();
            _cache.Remove($"VERIFIED_{request.Email}");

            return Ok(new { message = "Tạo tài khoản thành công!" });
        }

        // ==========================================
        // 3. API ĐĂNG NHẬP (TRUYỀN THỐNG) - ĐÃ FIX
        // ==========================================
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            if (request == null) return BadRequest(new { message = "Dữ liệu không hợp lệ!" });

            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == request.Email);

            if (user == null)
                return BadRequest(new { message = "Email hoặc mật khẩu không chính xác!" });

            bool isPasswordValid = false;
            try 
            {
                isPasswordValid = BCrypt.Net.BCrypt.Verify(request.Password, user.Passwordhash);
            } 
            catch 
            {
                // Cửa hậu để hỗ trợ tài khoản test đồ án bị kẹt hash cũ
                isPasswordValid = (request.Password == user.Passwordhash);
            }

            if (!isPasswordValid)
                return BadRequest(new { message = "Email hoặc mật khẩu không chính xác!" });

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
                    coverUrl = user.Coverurl, 
                    bio = user.Bio
                }
            });
        }

        // ==========================================
        // 4. API DÀNH CHO DESKTOP: GỌI GOOGLE
        // ==========================================
        [HttpGet("desktop-login/{provider}")]
        public IActionResult DesktopLogin(string provider)
        {
            string scheme = provider.ToLower() switch
            {
                "google" => "Google",
                _ => string.Empty
            };

            if (string.IsNullOrEmpty(scheme)) return BadRequest(new { message = "Provider không hợp lệ." });

            var redirectUrl = Url.Action(nameof(ExternalLoginCallback), "Auth", new { returnUrl = "prochat://login" }, Request.Scheme);
            var properties = new AuthenticationProperties { RedirectUri = redirectUrl };

            return Challenge(properties, scheme);
        }

        // ==========================================
        // 5. HỨNG KẾT QUẢ GOOGLE VÀ TẠO TOKEN
        // ==========================================
        [HttpGet("callback")]
        public async Task<IActionResult> ExternalLoginCallback(string returnUrl = "prochat://login")
        {
            var authenticateResult = await HttpContext.AuthenticateAsync(CookieAuthenticationDefaults.AuthenticationScheme);

            if (!authenticateResult.Succeeded || authenticateResult.Principal == null) return BadRequest("Đăng nhập mạng xã hội thất bại!");

            var email = authenticateResult.Principal.FindFirst(ClaimTypes.Email)?.Value;
            var name = authenticateResult.Principal.FindFirst(ClaimTypes.Name)?.Value;
            var avatarUrl = authenticateResult.Principal.FindFirst("urn:google:picture")?.Value ?? authenticateResult.Principal.FindFirst("picture")?.Value;

            if (string.IsNullOrEmpty(email)) return BadRequest("Không lấy được Email!");

            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == email);

            if (user == null)
            {
                user = new User
                {
                    Email = email,
                    Fullname = name ?? "Người dùng Google",
                    Avatarurl = avatarUrl ?? "", 
                    Passwordhash = string.Empty, 
                    Createdat = DateTime.UtcNow,
                    Settings = new UserSettings()
                };

                _context.Users.Add(user);
                await _context.SaveChangesAsync();
            }
            else if (string.IsNullOrEmpty(user.Avatarurl) && !string.IsNullOrEmpty(avatarUrl))
            {
                user.Avatarurl = avatarUrl;
                await _context.SaveChangesAsync();
            }

            var token = GenerateJwtToken(user);
            await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);

            return Redirect($"{returnUrl}?token={Uri.EscapeDataString(token)}");
        }

        // ==========================================
        // 6A. QUÊN MẬT KHẨU BƯỚC 1: GỬI OTP
        // ==========================================
        [HttpPost("forgot-password-otp")]
        public async Task<IActionResult> ForgotPasswordOtp([FromBody] ForgotPasswordRequest request)
        {
            if (request == null || string.IsNullOrEmpty(request.Email)) return BadRequest(new { message = "Email không hợp lệ!" });

            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == request.Email);
            
            if (user == null) return BadRequest(new { message = "Email này chưa được đăng ký trong hệ thống!" });
            
            if (string.IsNullOrEmpty(user.Passwordhash)) 
                return BadRequest(new { message = "Tài khoản này được đăng nhập bằng Google. Vui lòng đăng nhập qua Google, không thể đổi mật khẩu!" });

            string otpCode = new Random().Next(100000, 999999).ToString();
            _cache.Set($"RESET_OTP_{request.Email}", otpCode, TimeSpan.FromMinutes(3));

            try
            {
                await SendEmailAsync(request.Email, otpCode, "Mã xác thực khôi phục mật khẩu");
                return Ok(new { message = "Đã gửi mã OTP khôi phục mật khẩu!" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi gửi mail: {ex.Message}" });
            }
        }

        // ==========================================
        // 6B. QUÊN MẬT KHẨU BƯỚC 2: XÁC THỰC OTP
        // ==========================================
        [HttpPost("verify-forgot-otp")]
        public IActionResult VerifyForgotOtp([FromBody] VerifyOtpRequest request)
        {
            if (request == null) return BadRequest(new { message = "Dữ liệu không hợp lệ!" });

            if (_cache.TryGetValue($"RESET_OTP_{request.Email}", out string? savedOtp) && savedOtp == request.Otp)
            {
                _cache.Set($"RESET_VERIFIED_{request.Email}", true, TimeSpan.FromMinutes(10));
                _cache.Remove($"RESET_OTP_{request.Email}");
                return Ok(new { message = "Xác thực OTP thành công!" });
            }
            return BadRequest(new { message = "Mã OTP không chính xác hoặc đã hết hạn!" });
        }

        // ==========================================
        // 6C. QUÊN MẬT KHẨU BƯỚC 3: ĐẶT LẠI MẬT KHẨU
        // ==========================================
        [HttpPost("reset-password")]
        public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequest request)
        {
            if (request == null) return BadRequest(new { message = "Dữ liệu không hợp lệ!" });

            if (!_cache.TryGetValue($"RESET_VERIFIED_{request.Email}", out bool isVerified) || !isVerified)
            {
                return BadRequest(new { message = "Vui lòng xác minh OTP trước khi đổi mật khẩu!" });
            }

            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == request.Email);
            if (user == null) return BadRequest(new { message = "Tài khoản không tồn tại!" });

            user.Passwordhash = BCrypt.Net.BCrypt.HashPassword(request.Password);
            await _context.SaveChangesAsync();
            _cache.Remove($"RESET_VERIFIED_{request.Email}");

            return Ok(new { message = "Đổi mật khẩu thành công!" });
        }

        // ==========================================
        // 7. HÀM TẠO JWT TOKEN
        // ==========================================
        private string GenerateJwtToken(User user)
        {
            var jwtSettings = _configuration.GetSection("Jwt");
            var key = Encoding.ASCII.GetBytes(jwtSettings["Key"]!);

            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(new[]
                {
                    new Claim("nameid", user.Id.ToString()),
                    new Claim("email", user.Email),
                    new Claim("fullname", user.Fullname ?? "")
                }),
                Expires = DateTime.UtcNow.AddDays(7),
                Issuer = jwtSettings["Issuer"],
                Audience = jwtSettings["Audience"],
                SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature)
            };

            var tokenHandler = new JwtSecurityTokenHandler();
            var token = tokenHandler.CreateToken(tokenDescriptor);
            return tokenHandler.WriteToken(token);
        }

        // ==========================================
        // 8. HÀM HỖ TRỢ: GỬI MAIL BẰNG GMAIL SMTP
        // ==========================================
        private async Task SendEmailAsync(string toEmail, string otpCode, string subjectTitle)
        {
            string fromEmail = "fvgfv123nam@gmail.com"; 
            string appPassword = "rfzu vlcq yuyp wrao"; 

            var client = new SmtpClient("smtp.gmail.com", 587)
            {
                EnableSsl = true,
                UseDefaultCredentials = false,
                Credentials = new NetworkCredential(fromEmail, appPassword)
            };

            var mailMessage = new MailMessage
            {
                From = new MailAddress(fromEmail, "ChatApp Security"),
                Subject = subjectTitle,
                Body = $"<h3>Chào mừng bạn đến với ChatApp!</h3>" +
                       $"<p>Mã xác thực OTP của bạn là: <strong style='font-size: 24px; color: blue;'>{otpCode}</strong></p>" +
                       $"<p>Mã này sẽ hết hạn trong vòng 3 phút. Vui lòng không chia sẻ mã này cho bất kỳ ai.</p>",
                IsBodyHtml = true,
            };
            mailMessage.To.Add(toEmail);

            await client.SendMailAsync(mailMessage);
        }
    }
}