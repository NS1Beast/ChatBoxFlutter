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

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
#warning To protect potentially sensitive information in your connection string, you should move it out of source code. You can avoid scaffolding the connection string by using the Name= syntax to read it from configuration - see https://go.microsoft.com/fwlink/?linkid=2131148. For more guidance on storing connection strings, see https://go.microsoft.com/fwlink/?LinkId=723263.
        => optionsBuilder.UseNpgsql("Host=localhost;Database=flutterchatapp;Username=postgres;Password=12345678");

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasPostgresExtension("pgcrypto");

        modelBuilder.Entity<Contact>(entity =>
        {
            entity.HasKey(e => new { e.Userid, e.Friendid }).HasName("contacts_pkey");

            entity.ToTable("contacts");

            entity.Property(e => e.Userid).HasColumnName("userid");
            entity.Property(e => e.Friendid).HasColumnName("friendid");
            entity.Property(e => e.Createdat)
                .HasDefaultValueSql("CURRENT_TIMESTAMP")
                .HasColumnName("createdat");
            entity.Property(e => e.Status)
                .HasMaxLength(20)
                .HasDefaultValueSql("'pending'::character varying")
                .HasColumnName("status");

            entity.HasOne(d => d.Friend).WithMany(p => p.ContactFriends)
                .HasForeignKey(d => d.Friendid)
                .HasConstraintName("contacts_friendid_fkey");

            entity.HasOne(d => d.User).WithMany(p => p.ContactUsers)
                .HasForeignKey(d => d.Userid)
                .HasConstraintName("contacts_userid_fkey");
        });

        modelBuilder.Entity<Conversation>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("conversations_pkey");

            entity.ToTable("conversations");

            entity.Property(e => e.Id)
                .HasDefaultValueSql("gen_random_uuid()")
                .HasColumnName("id");
            entity.Property(e => e.Createdat)
                .HasDefaultValueSql("CURRENT_TIMESTAMP")
                .HasColumnName("createdat");
            entity.Property(e => e.Groupavatarurl).HasColumnName("groupavatarurl");
            entity.Property(e => e.Groupname)
                .HasMaxLength(100)
                .HasColumnName("groupname");
            entity.Property(e => e.Isgroup)
                .HasDefaultValue(false)
                .HasColumnName("isgroup");
        });

        modelBuilder.Entity<Message>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("messages_pkey");

            entity.ToTable("messages");

            entity.HasIndex(e => new { e.Conversationid, e.Createdat }, "idx_messages_conversation").IsDescending(false, true);

            entity.Property(e => e.Id)
                .HasDefaultValueSql("gen_random_uuid()")
                .HasColumnName("id");
            entity.Property(e => e.Content).HasColumnName("content");
            entity.Property(e => e.Conversationid).HasColumnName("conversationid");
            entity.Property(e => e.Createdat)
                .HasDefaultValueSql("CURRENT_TIMESTAMP")
                .HasColumnName("createdat");
            entity.Property(e => e.Isdeleted)
                .HasDefaultValue(false)
                .HasColumnName("isdeleted");
            entity.Property(e => e.Metadata)
                .HasColumnType("jsonb")
                .HasColumnName("metadata");
            entity.Property(e => e.Senderid).HasColumnName("senderid");
            entity.Property(e => e.Type)
                .HasMaxLength(20)
                .HasDefaultValueSql("'text'::character varying")
                .HasColumnName("type");

            entity.HasOne(d => d.Conversation).WithMany(p => p.Messages)
                .HasForeignKey(d => d.Conversationid)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("messages_conversationid_fkey");

            entity.HasOne(d => d.Sender).WithMany(p => p.Messages)
                .HasForeignKey(d => d.Senderid)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("messages_senderid_fkey");
        });

        modelBuilder.Entity<Participant>(entity =>
        {
            entity.HasKey(e => new { e.Conversationid, e.Userid }).HasName("participants_pkey");

            entity.ToTable("participants");

            entity.Property(e => e.Conversationid).HasColumnName("conversationid");
            entity.Property(e => e.Userid).HasColumnName("userid");
            entity.Property(e => e.Joinedat)
                .HasDefaultValueSql("CURRENT_TIMESTAMP")
                .HasColumnName("joinedat");
            entity.Property(e => e.Lastreadmessageid).HasColumnName("lastreadmessageid");
            entity.Property(e => e.Role)
                .HasMaxLength(20)
                .HasDefaultValueSql("'member'::character varying")
                .HasColumnName("role");

            entity.HasOne(d => d.Conversation).WithMany(p => p.Participants)
                .HasForeignKey(d => d.Conversationid)
                .HasConstraintName("participants_conversationid_fkey");

            entity.HasOne(d => d.User).WithMany(p => p.Participants)
                .HasForeignKey(d => d.Userid)
                .HasConstraintName("participants_userid_fkey");
        });

        modelBuilder.Entity<Post>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("posts_pkey");

            entity.ToTable("posts");

            entity.Property(e => e.Id)
                .HasDefaultValueSql("gen_random_uuid()")
                .HasColumnName("id");
            entity.Property(e => e.Commentscount)
                .HasDefaultValue(0)
                .HasColumnName("commentscount");
            entity.Property(e => e.Content).HasColumnName("content");
            entity.Property(e => e.Createdat)
                .HasDefaultValueSql("CURRENT_TIMESTAMP")
                .HasColumnName("createdat");
            entity.Property(e => e.Likescount)
                .HasDefaultValue(0)
                .HasColumnName("likescount");
            entity.Property(e => e.Mediatype)
                .HasMaxLength(20)
                .HasDefaultValueSql("'none'::character varying")
                .HasColumnName("mediatype");
            entity.Property(e => e.Mediaurl).HasColumnName("mediaurl");
            entity.Property(e => e.Userid).HasColumnName("userid");

            entity.HasOne(d => d.User).WithMany(p => p.Posts)
                .HasForeignKey(d => d.Userid)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("posts_userid_fkey");
        });

        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("users_pkey");

            entity.ToTable("users");

            entity.HasIndex(e => e.Email, "users_email_key").IsUnique();

            entity.Property(e => e.Id)
                .HasDefaultValueSql("gen_random_uuid()")
                .HasColumnName("id");
            entity.Property(e => e.Avatarurl).HasColumnName("avatarurl");
            entity.Property(e => e.Bio)
                .HasMaxLength(255)
                .HasColumnName("bio");
            entity.Property(e => e.Createdat)
                .HasDefaultValueSql("CURRENT_TIMESTAMP")
                .HasColumnName("createdat");
            entity.Property(e => e.Email)
                .HasMaxLength(255)
                .HasColumnName("email");
            entity.Property(e => e.Fullname)
                .HasMaxLength(100)
                .HasColumnName("fullname");
            entity.Property(e => e.Passwordhash)
                .HasMaxLength(255)
                .HasColumnName("passwordhash");
            entity.Property(e => e.Settings)
                .HasDefaultValueSql("'{\"theme\": \"light\", \"auto_download\": true, \"notifications\": true}'::jsonb")
                .HasColumnType("jsonb")
                .HasColumnName("settings");
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
