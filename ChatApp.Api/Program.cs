using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication.Google; // 🎯 BẮT BUỘC PHẢI CÓ DÒNG NÀY ĐỂ TRÁNH LỖI SCHEME 'Google'
using Microsoft.IdentityModel.Tokens;
using System.Text;
using Microsoft.EntityFrameworkCore;
using ChatApp.Api.Models; 
using ChatApp.Api.Services; 
using ChatApp.Api.Hubs; 
using Npgsql;

var builder = WebApplication.CreateBuilder(args);

// ==========================================
// 1. DATABASE POSTGRESQL
// ==========================================
var connString = builder.Configuration.GetConnectionString("DefaultConnection");
var dataSourceBuilder = new NpgsqlDataSourceBuilder(connString);
dataSourceBuilder.EnableDynamicJson(); 
var dataSource = dataSourceBuilder.Build();

builder.Services.AddDbContext<ChatDbContext>(options =>
    options.UseNpgsql(dataSource));

// ==========================================
// 2. CONTROLLERS & SERVICES
// ==========================================
builder.Services.AddControllers();
builder.Services.AddMemoryCache();
builder.Services.AddSingleton<EncryptionService>();

// ==========================================
// 3. SIGNALR & CORS
// ==========================================
builder.Services.AddSignalR();
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutterApp", policy =>
        policy.SetIsOriginAllowed(_ => true) 
            .AllowAnyMethod()
            .AllowAnyHeader()
            .AllowCredentials());
});

// ==========================================
// 4. 🎯 CẤU HÌNH AUTHENTICATION CHUẨN KÉP (TÁCH BẠCH RÕ RÀNG)
// ==========================================
builder.Services.AddAuthentication(options =>
{
    // Mặc định API và SignalR check quyền bằng JWT
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    
    // 🎯 CHÌA KHÓA Ở ĐÂY: Bắt buộc dùng Cookie để lưu trạng thái tạm khi SignIn Google
    options.DefaultSignInScheme = CookieAuthenticationDefaults.AuthenticationScheme;
})
// Khai báo Scheme 1: JWT Bearer (Dùng cho SignalR và API)
.AddJwtBearer(JwtBearerDefaults.AuthenticationScheme, options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"],
        ValidAudience = builder.Configuration["Jwt:Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]!))
    };

    // Bắt token từ URL cho SignalR
    options.Events = new JwtBearerEvents
    {
        OnMessageReceived = context =>
        {
            var accessToken = context.Request.Query["access_token"];
            var path = context.HttpContext.Request.Path;
            if (!string.IsNullOrEmpty(accessToken) && path.StartsWithSegments("/chatHub"))
            {
                context.Token = accessToken;
            }
            return Task.CompletedTask;
        }
    };
})
// Khai báo Scheme 2: Cookie
.AddCookie(CookieAuthenticationDefaults.AuthenticationScheme)
// Khai báo Scheme 3: Google
.AddGoogle(GoogleDefaults.AuthenticationScheme, options =>
{
    options.ClientId = builder.Configuration["Authentication:Google:ClientId"]!;
    options.ClientSecret = builder.Configuration["Authentication:Google:ClientSecret"]!;
    // Ràng buộc Google phải xài Cookie để lưu state
    options.SignInScheme = CookieAuthenticationDefaults.AuthenticationScheme;
});

// ==========================================
// 5. SWAGGER
// ==========================================
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// HTTP REQUEST PIPELINE
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseCors("AllowFlutterApp");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapHub<ChatHub>("/chatHub");

app.Run();