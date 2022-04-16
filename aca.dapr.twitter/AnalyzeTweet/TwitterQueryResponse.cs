namespace ReadTwitter;

using System;
using System.Text.Json.Serialization;

public partial class TwitterQueryResponse
{
    [JsonPropertyName("coordinates")]
    public object Coordinates { get; set; }

    [JsonPropertyName("created_at")]
    public string CreatedAt { get; set; }

    [JsonPropertyName("current_user_retweet")]
    public object CurrentUserRetweet { get; set; }

    [JsonPropertyName("entities")]
    public Entities Entities { get; set; }

    [JsonPropertyName("favorite_count")]
    public long FavoriteCount { get; set; }

    [JsonPropertyName("favorited")]
    public bool Favorited { get; set; }

    [JsonPropertyName("filter_level")]
    public string FilterLevel { get; set; }

    [JsonPropertyName("id")]
    public double Id { get; set; }

    [JsonPropertyName("id_str")]
    public string IdStr { get; set; }

    [JsonPropertyName("in_reply_to_screen_name")]
    public string InReplyToScreenName { get; set; }

    [JsonPropertyName("in_reply_to_status_id")]
    public long InReplyToStatusId { get; set; }

    [JsonPropertyName("in_reply_to_status_id_str")]
    public string InReplyToStatusIdStr { get; set; }

    [JsonPropertyName("in_reply_to_user_id")]
    public long InReplyToUserId { get; set; }

    [JsonPropertyName("in_reply_to_user_id_str")]
    public string InReplyToUserIdStr { get; set; }

    [JsonPropertyName("lang")]
    public string Lang { get; set; }

    [JsonPropertyName("possibly_sensitive")]
    public bool PossiblySensitive { get; set; }

    [JsonPropertyName("quote_count")]
    public long QuoteCount { get; set; }

    [JsonPropertyName("reply_count")]
    public long ReplyCount { get; set; }

    [JsonPropertyName("retweet_count")]
    public long RetweetCount { get; set; }

    [JsonPropertyName("retweeted")]
    public bool Retweeted { get; set; }

    [JsonPropertyName("retweeted_status")]
    public TwitterQueryResponse RetweetedStatus { get; set; }

    [JsonPropertyName("source")]
    public string Source { get; set; }

    [JsonPropertyName("scopes")]
    public object Scopes { get; set; }

    [JsonPropertyName("text")]
    public string Text { get; set; }

    [JsonPropertyName("full_text")]
    public string FullText { get; set; }

    [JsonPropertyName("display_text_range")]
    public long[] DisplayTextRange { get; set; }

    [JsonPropertyName("place")]
    public object Place { get; set; }

    [JsonPropertyName("truncated")]
    public bool Truncated { get; set; }

    [JsonPropertyName("user")]
    public User User { get; set; }

    [JsonPropertyName("withheld_copyright")]
    public bool WithheldCopyright { get; set; }

    [JsonPropertyName("withheld_in_countries")]
    public object WithheldInCountries { get; set; }

    [JsonPropertyName("withheld_scope")]
    public string WithheldScope { get; set; }

    [JsonPropertyName("extended_entities")]
    public object ExtendedEntities { get; set; }

    [JsonPropertyName("extended_tweet")]
    public ExtendedTweet ExtendedTweet { get; set; }

    [JsonPropertyName("quoted_status_id")]
    public long QuotedStatusId { get; set; }

    [JsonPropertyName("quoted_status_id_str")]
    public string QuotedStatusIdStr { get; set; }

    [JsonPropertyName("quoted_status")]
    public object QuotedStatus { get; set; }
}

public partial class Entities
{
    [JsonPropertyName("hashtags")]
    public Hashtag[] Hashtags { get; set; }

    [JsonPropertyName("media")]
    public Media[] Media { get; set; }

    [JsonPropertyName("urls")]
    public Url[] Urls { get; set; }

    [JsonPropertyName("user_mentions")]
    public UserMention[] UserMentions { get; set; }
}

public partial class Hashtag
{
    [JsonPropertyName("indices")]
    public long[] Indices { get; set; }

    [JsonPropertyName("text")]
    public string Text { get; set; }
}

public partial class Media
{
    [JsonPropertyName("indices")]
    public long[] Indices { get; set; }

    [JsonPropertyName("display_url")]
    public string DisplayUrl { get; set; }

    [JsonPropertyName("expanded_url")]
    public Uri ExpandedUrl { get; set; }

    [JsonPropertyName("url")]
    public Uri Url { get; set; }

    [JsonPropertyName("id")]
    public double Id { get; set; }

    [JsonPropertyName("id_str")]
    public string IdStr { get; set; }

    [JsonPropertyName("media_url")]
    public Uri MediaUrl { get; set; }

    [JsonPropertyName("media_url_https")]
    public Uri MediaUrlHttps { get; set; }

    [JsonPropertyName("source_status_id")]
    public long SourceStatusId { get; set; }

    [JsonPropertyName("source_status_id_str")]
    public string SourceStatusIdStr { get; set; }

    [JsonPropertyName("type")]
    public string Type { get; set; }

    [JsonPropertyName("sizes")]
    public Sizes Sizes { get; set; }

    [JsonPropertyName("video_info")]
    public VideoInfo VideoInfo { get; set; }
}

public partial class Sizes
{
    [JsonPropertyName("thumb")]
    public Large Thumb { get; set; }

    [JsonPropertyName("large")]
    public Large Large { get; set; }

    [JsonPropertyName("medium")]
    public Large Medium { get; set; }

    [JsonPropertyName("small")]
    public Large Small { get; set; }
}

public partial class Large
{
    [JsonPropertyName("w")]
    public long W { get; set; }

    [JsonPropertyName("h")]
    public long H { get; set; }

    [JsonPropertyName("resize")]
    public string Resize { get; set; }
}

public partial class VideoInfo
{
    [JsonPropertyName("aspect_ratio")]
    public long[] AspectRatio { get; set; }

    [JsonPropertyName("duration_millis")]
    public long DurationMillis { get; set; }

    [JsonPropertyName("variants")]
    public Variant[] Variants { get; set; }
}

public partial class Variant
{
    [JsonPropertyName("content_type")]
    public string ContentType { get; set; }

    [JsonPropertyName("bitrate")]
    public long Bitrate { get; set; }

    [JsonPropertyName("url")]
    public Uri Url { get; set; }
}

public partial class Url
{
    [JsonPropertyName("indices")]
    public long[] Indices { get; set; }

    [JsonPropertyName("display_url")]
    public string DisplayUrl { get; set; }

    [JsonPropertyName("expanded_url")]
    public Uri ExpandedUrl { get; set; }

    [JsonPropertyName("url")]
    public Uri UrlUrl { get; set; }
}

public partial class UserMention
{
    [JsonPropertyName("indices")]
    public long[] Indices { get; set; }

    [JsonPropertyName("id")]
    public long Id { get; set; }

    [JsonPropertyName("id_str")]
    public object IdStr { get; set; }

    [JsonPropertyName("name")]
    public string Name { get; set; }

    [JsonPropertyName("screen_name")]
    public string ScreenName { get; set; }
}

public partial class ExtendedTweet
{
    [JsonPropertyName("full_text")]
    public string FullText { get; set; }

    [JsonPropertyName("display_text_range")]
    public long[] DisplayTextRange { get; set; }

    [JsonPropertyName("entities")]
    public Entities Entities { get; set; }

    [JsonPropertyName("extended_entities")]
    public ExtendedEntities ExtendedEntities { get; set; }
}

public partial class ExtendedEntities
{
    [JsonPropertyName("media")]
    public Media[] Media { get; set; }
}

public partial class User
{
    [JsonPropertyName("contributors_enabled")]
    public bool ContributorsEnabled { get; set; }

    [JsonPropertyName("created_at")]
    public string CreatedAt { get; set; }

    [JsonPropertyName("default_profile")]
    public bool DefaultProfile { get; set; }

    [JsonPropertyName("default_profile_image")]
    public bool DefaultProfileImage { get; set; }

    [JsonPropertyName("description")]
    public string Description { get; set; }

    [JsonPropertyName("email")]
    public string Email { get; set; }

    [JsonPropertyName("entities")]
    public object Entities { get; set; }

    [JsonPropertyName("favourites_count")]
    public long FavouritesCount { get; set; }

    [JsonPropertyName("follow_request_sent")]
    public bool FollowRequestSent { get; set; }

    [JsonPropertyName("following")]
    public bool Following { get; set; }

    [JsonPropertyName("followers_count")]
    public long FollowersCount { get; set; }

    [JsonPropertyName("friends_count")]
    public long FriendsCount { get; set; }

    [JsonPropertyName("geo_enabled")]
    public bool GeoEnabled { get; set; }

    [JsonPropertyName("id")]
    public double Id { get; set; }

    [JsonPropertyName("id_str")]
    public string IdStr { get; set; }

    [JsonPropertyName("is_translator")]
    public bool IsTranslator { get; set; }

    [JsonPropertyName("lang")]
    public string Lang { get; set; }

    [JsonPropertyName("listed_count")]
    public long ListedCount { get; set; }

    [JsonPropertyName("location")]
    public string Location { get; set; }

    [JsonPropertyName("name")]
    public string Name { get; set; }

    [JsonPropertyName("notifications")]
    public bool Notifications { get; set; }

    [JsonPropertyName("profile_background_color")]
    public string ProfileBackgroundColor { get; set; }

    [JsonPropertyName("profile_background_image_url")]
    public string ProfileBackgroundImageUrl { get; set; }

    [JsonPropertyName("profile_background_image_url_https")]
    public string ProfileBackgroundImageUrlHttps { get; set; }

    [JsonPropertyName("profile_background_tile")]
    public bool ProfileBackgroundTile { get; set; }

    [JsonPropertyName("profile_banner_url")]
    public Uri ProfileBannerUrl { get; set; }

    [JsonPropertyName("profile_image_url")]
    public Uri ProfileImageUrl { get; set; }

    [JsonPropertyName("profile_image_url_https")]
    public Uri ProfileImageUrlHttps { get; set; }

    [JsonPropertyName("profile_link_color")]
    public string ProfileLinkColor { get; set; }

    [JsonPropertyName("profile_sidebar_border_color")]
    public string ProfileSidebarBorderColor { get; set; }

    [JsonPropertyName("profile_sidebar_fill_color")]
    public string ProfileSidebarFillColor { get; set; }

    [JsonPropertyName("profile_text_color")]
    public object ProfileTextColor { get; set; }

    [JsonPropertyName("profile_use_background_image")]
    public bool ProfileUseBackgroundImage { get; set; }

    [JsonPropertyName("protected")]
    public bool Protected { get; set; }

    [JsonPropertyName("screen_name")]
    public string ScreenName { get; set; }

    [JsonPropertyName("show_all_inline_media")]
    public bool ShowAllInlineMedia { get; set; }

    [JsonPropertyName("status")]
    public object Status { get; set; }

    [JsonPropertyName("statuses_count")]
    public long StatusesCount { get; set; }

    [JsonPropertyName("time_zone")]
    public string TimeZone { get; set; }

    [JsonPropertyName("url")]
    public string Url { get; set; }

    [JsonPropertyName("utc_offset")]
    public long UtcOffset { get; set; }

    [JsonPropertyName("verified")]
    public bool Verified { get; set; }

    [JsonPropertyName("withheld_in_countries")]
    public object WithheldInCountries { get; set; }

    [JsonPropertyName("withheld_scope")]
    public string WithheldScope { get; set; }
}