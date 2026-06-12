using ChatApp.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace ChatApp.Api.Services
{
    public class MessageCleanupService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<MessageCleanupService> _logger;

        public MessageCleanupService(IServiceProvider serviceProvider, ILogger<MessageCleanupService> logger)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        // Chạy service nền để tự động dọn các tin nhắn cũ
        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("Dịch vụ dọn rác tin nhắn đã khởi động.");

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    using (var scope = _serviceProvider.CreateScope())
                    {
                        var dbContext = scope.ServiceProvider.GetRequiredService<ChatDbContext>();

                        // Xác định mốc thời gian để xóa tin nhắn cũ
                        var sevenDaysAgo = DateTime.UtcNow.AddDays(-7);

                        // Lấy các tin nhắn đã quá thời hạn lưu trữ
                        var oldMessages = dbContext.Messages
                            .Where(m => m.CreatedAt < sevenDaysAgo);

                        int count = await oldMessages.CountAsync(stoppingToken);

                        if (count > 0)
                        {
                            dbContext.Messages.RemoveRange(oldMessages);
                            await dbContext.SaveChangesAsync(stoppingToken);

                            _logger.LogInformation("Đã dọn dẹp {Count} tin nhắn quá 7 ngày.", count);
                        }
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Lỗi trong lúc dọn rác tin nhắn.");
                }

                // Lặp lại quá trình dọn dẹp mỗi 24 giờ
                await Task.Delay(TimeSpan.FromHours(24), stoppingToken);
            }
        }
    }
}