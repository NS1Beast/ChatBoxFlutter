using System.Threading.Channels;
using ChatApp.Api.Models;

namespace ChatApp.Api.Services
{
    public class MessageQueue
    {
        private readonly Channel<Message> _queue;

        public MessageQueue()
        {
            // Tạo hàng đợi giới hạn để tránh quá tải bộ nhớ khi có nhiều tin nhắn
            var options = new BoundedChannelOptions(10000)
            {
                FullMode = BoundedChannelFullMode.Wait
            };

            _queue = Channel.CreateBounded<Message>(options);
        }

        // Thêm tin nhắn vào hàng đợi để xử lý lưu database
        public async ValueTask EnqueueAsync(Message message)
        {
            await _queue.Writer.WriteAsync(message);
        }

        // Đọc lần lượt các tin nhắn trong hàng đợi
        public IAsyncEnumerable<Message> DequeueAsync(CancellationToken ct)
        {
            return _queue.Reader.ReadAllAsync(ct);
        }
    }

    public class MessageProcessorService : BackgroundService
    {
        private readonly MessageQueue _queue;
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<MessageProcessorService> _logger;

        public MessageProcessorService(
            MessageQueue queue,
            IServiceProvider serviceProvider,
            ILogger<MessageProcessorService> logger)
        {
            _queue = queue;
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        // Chạy nền để lấy tin nhắn từ hàng đợi và lưu vào database
        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            await foreach (var msg in _queue.DequeueAsync(stoppingToken))
            {
                try
                {
                    using var scope = _serviceProvider.CreateScope();
                    var db = scope.ServiceProvider.GetRequiredService<ChatDbContext>();

                    db.Messages.Add(msg);
                    await db.SaveChangesAsync(stoppingToken);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Lỗi khi lưu tin nhắn vào database.");
                }
            }
        }
    }
}