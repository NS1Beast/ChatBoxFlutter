using System;
using System.Collections.Generic;

namespace ChatApp.Api.Models;

public partial class Contact
{
    public Guid Userid { get; set; }

    public Guid Friendid { get; set; }

    public string? Status { get; set; }

    public DateTime? Createdat { get; set; }

    public virtual User Friend { get; set; } = null!;

    public virtual User User { get; set; } = null!;
}
