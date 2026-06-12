using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication.Google;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using Microsoft.EntityFrameworkCore;
using ChatApp.Api.Models;
using ChatApp.Api.Services;
using ChatApp.Api.Hubs;
using Npgsql;

var builder = WebApplication.CreateBuilder(args);

// Cấu hình PostgreSQL và bật hỗ trợ JSON động cho Npgsql
var connString = builder.Configuration.GetConnectionString("DefaultConnection");
var dataSourceBuilder = new NpgsqlDataSourceBuilder(connString);
dataSourceBuilder.EnableDynamicJson();

var dataSource = dataSourceBuilder.Build();

builder.Services.AddDbContext<ChatDbContext>(options =>
    options.UseNpgsql(dataSource));

// Đăng ký controller, cache và các service xử lý nghiệp vụ
builder.Services.AddControllers();
builder.Services.AddMemoryCache();
builder.Services.AddSingleton<EncryptionService>();
builder.Services.AddHostedService<MessageCleanupService>();

// Đăng ký hàng đợi và service chạy nền để lưu tin nhắn vào database
builder.Services.AddSingleton<MessageQueue>();
builder.Services.AddHostedService<MessageProcessorService>();

// Cấu hình SignalR cho realtime chat và call
var signalRBuilder = builder.Services.AddSignalR();

// Redis backplane dùng khi cần scale SignalR nhiều server
// signalRBuilder.AddStackExchangeRedis("localhost:6379", options =>
// {
//     options.Configuration.ChannelPrefix = "ChatApp_Prod";
// });

// Cho phép Flutter app gọi API và SignalR
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutterApp", policy =>
        policy.SetIsOriginAllowed(_ => true)
            .AllowAnyMethod()
            .AllowAnyHeader()
            .AllowCredentials());
});

// Cấu hình xác thực bằng JWT cho API, SignalR và Cookie cho Google login
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultSignInScheme = CookieAuthenticationDefaults.AuthenticationScheme;
})
.AddJwtBearer(JwtBearerDefaults.AuthenticationScheme, options =>
{
    // Kiểm tra JWT token khi client gọi API hoặc kết nối SignalR
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"],
        ValidAudience = builder.Configuration["Jwt:Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]!)
        )
    };

    // Lấy access_token từ query string khi Flutter kết nối SignalR
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
.AddCookie(CookieAuthenticationDefaults.AuthenticationScheme)
.AddGoogle(GoogleDefaults.AuthenticationScheme, options =>
{
    // Cấu hình Google OAuth cho đăng nhập mạng xã hội
    options.ClientId = builder.Configuration["Authentication:Google:ClientId"]!;
    options.ClientSecret = builder.Configuration["Authentication:Google:ClientSecret"]!;
    options.SignInScheme = CookieAuthenticationDefaults.AuthenticationScheme;
});

// Cấu hình Swagger để test API trong môi trường development
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Bật Swagger khi chạy development
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