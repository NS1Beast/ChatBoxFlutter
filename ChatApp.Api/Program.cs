using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.EntityFrameworkCore;
using ChatApp.Api.Models;
using Npgsql;

var builder = WebApplication.CreateBuilder(args);

// ==========================================
// 1. DATABASE POSTGRESQL (NÂNG CẤP HỖ TRỢ JSONB)
// ==========================================
var connString = builder.Configuration.GetConnectionString("DefaultConnection");
var dataSourceBuilder = new NpgsqlDataSourceBuilder(connString);

// Bật tính năng convert tự động JSONB sang Object C#
dataSourceBuilder.EnableDynamicJson(); 
var dataSource = dataSourceBuilder.Build();

builder.Services.AddDbContext<ChatDbContext>(options =>
    options.UseNpgsql(dataSource));

// 2. CONTROLLERS
builder.Services.AddControllers();
builder.Services.AddMemoryCache();
// 3. SIGNALR
builder.Services.AddSignalR();

// 4. CORS CHO FLUTTER
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutterApp", policy =>
        policy.AllowAnyOrigin()
            .AllowAnyMethod()
            .AllowAnyHeader());
});

// 5. CẤU HÌNH ĐĂNG NHẬP GOOGLE
builder.Services.AddAuthentication(options =>
{
    // Cookie dùng để giữ trạng thái tạm trong lúc redirect qua Google
    options.DefaultScheme = CookieAuthenticationDefaults.AuthenticationScheme;
})
.AddCookie()
.AddGoogle(options =>
{
    options.ClientId = builder.Configuration["Authentication:Google:ClientId"]!;
    options.ClientSecret = builder.Configuration["Authentication:Google:ClientSecret"]!;

    // Callback mặc định: /signin-google
});

// 6. SWAGGER
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

// CORS đặt trước Authentication / Authorization
app.UseCors("AllowFlutterApp");

// Authentication phải đặt trước Authorization
app.UseAuthentication();

app.UseAuthorization();

// Map Controllers
app.MapControllers();

// Sau này có ChatHub thì mở dòng này:
// app.MapHub<ChatHub>("/chathub");

app.Run();