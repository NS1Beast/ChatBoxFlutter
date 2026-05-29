using System;
using System.Collections.Generic;

namespace ChatApp.Api.Models;

public partial class User
{
    public Guid Id { get; set; }

    public string Email { get; set; } = null!;

    public string Passwordhash { get; set; } = null!;

    public string Fullname { get; set; } = null!;

    public string? Avatarurl { get; set; }

    public string? Bio { get; set; }

    public DateTime? Createdat { get; set; }

    public virtual ICollection<Contact> ContactFriends { get; set; } = new List<Contact>();

    public virtual ICollection<Contact> ContactUsers { get; set; } = new List<Contact>();

    public virtual ICollection<Message> Messages { get; set; } = new List<Message>();

    public virtual ICollection<Participant> Participants { get; set; } = new List<Participant>();

    public virtual ICollection<Post> Posts { get; set; } = new List<Post>();

    public UserSettings Settings { get; set; } = new UserSettings();
}