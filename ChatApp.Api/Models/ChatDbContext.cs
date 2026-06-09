using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace ChatApp.Api.Models;

public partial class ChatDbContext : DbContext
{
    public ChatDbContext()
    {
    }

    public ChatDbContext(DbContextOptions<ChatDbContext> options)
        : base(options)
    {
    }

    public virtual DbSet<Contact> Contacts { get; set; }
    public virtual DbSet<Conversation> Conversations { get; set; }
    public virtual DbSet<Message> Messages { get; set; }
    public virtual DbSet<Participant> Participants { get; set; }
    public virtual DbSet<Post> Posts { get; set; }
    public virtual DbSet<User> Users { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasPostgresExtension("pgcrypto");

        // BẢNG CONTACT (Tui giữ nguyên để không vỡ code cũ của ông)
        modelBuilder.Entity<Contact>(entity =>
        {
            entity.HasKey(e => new { e.Userid, e.Friendid }).HasName("contacts_pkey");
            entity.ToTable("contacts");
            entity.Property(e => e.Userid).HasColumnName("userid");
            entity.Property(e => e.Friendid).HasColumnName("friendid");
            entity.Property(e => e.Createdat).HasDefaultValueSql("CURRENT_TIMESTAMP").HasColumnName("createdat");
            entity.Property(e => e.Status).HasMaxLength(20).HasDefaultValueSql("'pending'::character varying").HasColumnName("status");
            entity.HasOne(d => d.Friend).WithMany(p => p.ContactFriends).HasForeignKey(d => d.Friendid).HasConstraintName("contacts_friendid_fkey");
            entity.HasOne(d => d.User).WithMany(p => p.ContactUsers).HasForeignKey(d => d.Userid).HasConstraintName("contacts_userid_fkey");
        });

        // ==========================================
        // 🎯 BẢNG CONVERSATION ĐÃ CHUẨN HÓA CÚ PHÁP
        // ==========================================
        modelBuilder.Entity<Conversation>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("conversations_pkey");
            entity.ToTable("conversations");
            entity.Property(e => e.Id).HasDefaultValueSql("gen_random_uuid()").HasColumnName("id");
            
            // Đã sửa thành IsGroup, CreatedAt, GroupName...
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP").HasColumnName("createdat");
            entity.Property(e => e.GroupAvatarUrl).HasColumnName("groupavatarurl");
            entity.Property(e => e.GroupName).HasMaxLength(100).HasColumnName("groupname");
            entity.Property(e => e.IsGroup).HasDefaultValue(false).HasColumnName("isgroup");
        });

        // ==========================================
        // 🎯 BẢNG MESSAGE ĐÃ TÍCH HỢP MÃ HÓA AES-GCM
        // ==========================================
        modelBuilder.Entity<Message>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("messages_pkey");
            entity.ToTable("messages");
            
            // Đã sửa cú pháp: ConversationId, CreatedAt
            entity.HasIndex(e => new { e.ConversationId, e.CreatedAt }, "idx_messages_conversation").IsDescending(false, true);

            entity.Property(e => e.Id).HasDefaultValueSql("gen_random_uuid()").HasColumnName("id");
            
            // 🎯 XÓA CONTENT, ĐƯA BỘ TỨ BẢO MẬT VÀO ĐÂY
            entity.Property(e => e.Ciphertext).HasColumnName("ciphertext");
            entity.Property(e => e.Nonce).HasMaxLength(100).HasColumnName("nonce");
            entity.Property(e => e.Tag).HasMaxLength(100).HasColumnName("tag");
            entity.Property(e => e.KeyId).HasMaxLength(50).HasDefaultValueSql("'v1'::character varying").HasColumnName("keyid");

            entity.Property(e => e.ConversationId).HasColumnName("conversationid");
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP").HasColumnName("createdat");
            entity.Property(e => e.IsDeleted).HasDefaultValue(false).HasColumnName("isdeleted");
            entity.Property(e => e.Metadata).HasColumnType("jsonb").HasColumnName("metadata");
            entity.Property(e => e.SenderId).HasColumnName("senderid");
            entity.Property(e => e.Type).HasMaxLength(20).HasDefaultValueSql("'text'::character varying").HasColumnName("type");

            entity.HasOne(d => d.Conversation).WithMany(p => p.Messages).HasForeignKey(d => d.ConversationId).OnDelete(DeleteBehavior.Cascade).HasConstraintName("messages_conversationid_fkey");
            entity.HasOne(d => d.Sender).WithMany(p => p.Messages).HasForeignKey(d => d.SenderId).OnDelete(DeleteBehavior.SetNull).HasConstraintName("messages_senderid_fkey");
        });

        // ==========================================
        // 🎯 BẢNG PARTICIPANT ĐÃ CHUẨN HÓA CÚ PHÁP
        // ==========================================
        modelBuilder.Entity<Participant>(entity =>
        {
            // Đã sửa: ConversationId, UserId
            entity.HasKey(e => new { e.ConversationId, e.UserId }).HasName("participants_pkey");
            entity.ToTable("participants");

            entity.Property(e => e.ConversationId).HasColumnName("conversationid");
            entity.Property(e => e.UserId).HasColumnName("userid");
            entity.Property(e => e.JoinedAt).HasDefaultValueSql("CURRENT_TIMESTAMP").HasColumnName("joinedat");
            entity.Property(e => e.LastReadMessageId).HasColumnName("lastreadmessageid");
            entity.Property(e => e.Role).HasMaxLength(20).HasDefaultValueSql("'member'::character varying").HasColumnName("role");
            
            // Giữ lại cấu hình mở rộng của ông
            // entity.Property(e => e.ChatSettings).HasDefaultValueSql("'{\"mute_notifications\": false, \"theme_color\": \"default\", \"nickname\": null}'::jsonb").HasColumnType("jsonb").HasColumnName("chatsettings");

            entity.HasOne(d => d.Conversation).WithMany(p => p.Participants).HasForeignKey(d => d.ConversationId).HasConstraintName("participants_conversationid_fkey");
            entity.HasOne(d => d.User).WithMany(p => p.Participants).HasForeignKey(d => d.UserId).HasConstraintName("participants_userid_fkey");
        });

        // BẢNG POST (Tui giữ nguyên)
        modelBuilder.Entity<Post>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("posts_pkey");
            entity.ToTable("posts");
            entity.Property(e => e.Id).HasDefaultValueSql("gen_random_uuid()").HasColumnName("id");
            entity.Property(e => e.Commentscount).HasDefaultValue(0).HasColumnName("commentscount");
            entity.Property(e => e.Content).HasColumnName("content");
            entity.Property(e => e.Createdat).HasDefaultValueSql("CURRENT_TIMESTAMP").HasColumnName("createdat");
            entity.Property(e => e.Likescount).HasDefaultValue(0).HasColumnName("likescount");
            entity.Property(e => e.Mediatype).HasMaxLength(20).HasDefaultValueSql("'none'::character varying").HasColumnName("mediatype");
            entity.Property(e => e.Mediaurl).HasColumnName("mediaurl");
            entity.Property(e => e.Userid).HasColumnName("userid");
            entity.HasOne(d => d.User).WithMany(p => p.Posts).HasForeignKey(d => d.Userid).OnDelete(DeleteBehavior.Cascade).HasConstraintName("posts_userid_fkey");
        });

        // BẢNG USER (Tui giữ nguyên)
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("users_pkey");
            entity.ToTable("users");
            entity.HasIndex(e => e.Email, "users_email_key").IsUnique();
            entity.Property(e => e.Id).HasDefaultValueSql("gen_random_uuid()").HasColumnName("id");
            entity.Property(e => e.Avatarurl).HasColumnName("avatarurl");
            entity.Property(e => e.Bio).HasMaxLength(255).HasColumnName("bio");
            entity.Property(e => e.Createdat).HasDefaultValueSql("CURRENT_TIMESTAMP").HasColumnName("createdat");
            entity.Property(e => e.Email).HasMaxLength(255).HasColumnName("email");
            entity.Property(e => e.Fullname).HasMaxLength(100).HasColumnName("fullname");
            entity.Property(e => e.Passwordhash).HasMaxLength(255).HasColumnName("passwordhash");
            entity.Property(e => e.Settings).HasDefaultValueSql("'{\"theme\": \"light\", \"auto_download\": true, \"notifications\": true}'::jsonb").HasColumnType("jsonb").HasColumnName("settings");
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}