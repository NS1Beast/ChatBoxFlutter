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

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("🚀 Dịch vụ dọn rác tin nhắn đã khởi động!");

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    using (var scope = _serviceProvider.CreateScope())
                    {
                        var dbContext = scope.ServiceProvider.GetRequiredService<ChatDbContext>();
                        
                        // 🎯 Lấy thời điểm 7 ngày trước (1 tuần)
                        var sevenDaysAgo = DateTime.UtcNow.AddDays(-7);

                        // Tìm và XÓA sạch các tin nhắn cũ hơn 7 ngày
                        var oldMessages = dbContext.Messages
                            .Where(m => m.CreatedAt < sevenDaysAgo);

                        int count = await oldMessages.CountAsync(stoppingToken);
                        
                        if (count > 0)
                        {
                            dbContext.Messages.RemoveRange(oldMessages);
                            await dbContext.SaveChangesAsync(stoppingToken);
                            _logger.LogInformation($"🧹 Đã dọn dẹp sạch sẽ {count} tin nhắn quá 7 ngày trên Postgres!");
                        }
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Lỗi trong lúc dọn rác tin nhắn.");
                }

                // 🎯 Ngủ 24 tiếng rồi dậy dọn tiếp (Hoặc chỉnh thành TimeSpan.FromHours(1) nếu muốn test)
                await Task.Delay(TimeSpan.FromHours(24), stoppingToken); 
            }
        }
    }
}