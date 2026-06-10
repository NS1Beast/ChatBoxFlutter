using System.Threading.Channels;
using ChatApp.Api.Models;

namespace ChatApp.Api.Services
{
    // 1. CÁI BĂNG CHUYỀN (Kênh chứa tin nhắn)
    public class MessageQueue
    {
        private readonly Channel<Message> _queue;

        public MessageQueue()
        {
            // Tạo 1 hàng đợi chứa tối đa 10.000 tin nhắn cùng lúc
            var options = new BoundedChannelOptions(10000) { FullMode = BoundedChannelFullMode.Wait };
            _queue = Channel.CreateBounded<Message>(options);
        }

        public async ValueTask EnqueueAsync(Message message) => await _queue.Writer.WriteAsync(message);
        public IAsyncEnumerable<Message> DequeueAsync(CancellationToken ct) => _queue.Reader.ReadAllAsync(ct);
    }

    // 2. CÔNG NHÂN NHẶT TIN NHẮN (Chạy ngầm 24/7 không ảnh hưởng luồng chính)
    public class MessageProcessorService : BackgroundService
    {
        private readonly MessageQueue _queue;
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<MessageProcessorService> _logger;

        public MessageProcessorService(MessageQueue queue, IServiceProvider serviceProvider, ILogger<MessageProcessorService> logger)
        {
            _queue = queue;
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            await foreach (var msg in _queue.DequeueAsync(stoppingToken))
            {
                try
                {
                    // Vì BackgroundService là Singleton, ta phải tạo Scope mới để gọi DbContext
                    using var scope = _serviceProvider.CreateScope();
                    var db = scope.ServiceProvider.GetRequiredService<ChatDbContext>();
                    
                    db.Messages.Add(msg);
                    await db.SaveChangesAsync(stoppingToken);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "❌ Lỗi khi lưu tin nhắn vào Database ngầm!");
                }
            }
        }
    }
}