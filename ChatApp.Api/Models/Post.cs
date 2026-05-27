using System;
using System.Collections.Generic;

namespace ChatApp.Api.Models;

public partial class Post
{
    public Guid Id { get; set; }

    public Guid? Userid { get; set; }

    public string? Content { get; set; }

    public string? Mediatype { get; set; }

    public string? Mediaurl { get; set; }

    public int? Likescount { get; set; }

    public int? Commentscount { get; set; }

    public DateTime? Createdat { get; set; }

    public virtual User? User { get; set; }
}
