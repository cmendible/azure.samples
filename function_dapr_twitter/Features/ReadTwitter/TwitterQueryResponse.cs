namespace Function.ReadTwitter
{
    using System;
    using Newtonsoft.Json;

    public partial class Tweet
    {
        [JsonProperty("text")]
        public string Text { get; set; }

        [JsonProperty("user")]
        public string User { get; set; }
    }

    public partial class TwitterQueryResponse
    {
        [JsonProperty("coordinates")]
        public object Coordinates { get; set; }

        [JsonProperty("created_at")]
        public string CreatedAt { get; set; }

        [JsonProperty("current_user_retweet")]
        public object CurrentUserRetweet { get; set; }

        [JsonProperty("entities")]
        public Entities Entities { get; set; }

        [JsonProperty("favorite_count")]
        public long FavoriteCount { get; set; }

        [JsonProperty("favorited")]
        public bool Favorited { get; set; }

        [JsonProperty("filter_level")]
        public string FilterLevel { get; set; }

        [JsonProperty("id")]
        public double Id { get; set; }

        [JsonProperty("id_str")]
        public string IdStr { get; set; }

        [JsonProperty("in_reply_to_screen_name")]
        public string InReplyToScreenName { get; set; }

        [JsonProperty("in_reply_to_status_id")]
        public long InReplyToStatusId { get; set; }

        [JsonProperty("in_reply_to_status_id_str")]
        public string InReplyToStatusIdStr { get; set; }

        [JsonProperty("in_reply_to_user_id")]
        public long InReplyToUserId { get; set; }

        [JsonProperty("in_reply_to_user_id_str")]
        public string InReplyToUserIdStr { get; set; }

        [JsonProperty("lang")]
        public string Lang { get; set; }

        [JsonProperty("possibly_sensitive")]
        public bool PossiblySensitive { get; set; }

        [JsonProperty("quote_count")]
        public long QuoteCount { get; set; }

        [JsonProperty("reply_count")]
        public long ReplyCount { get; set; }

        [JsonProperty("retweet_count")]
        public long RetweetCount { get; set; }

        [JsonProperty("retweeted")]
        public bool Retweeted { get; set; }

        [JsonProperty("retweeted_status")]
        public TwitterQueryResponse RetweetedStatus { get; set; }

        [JsonProperty("source")]
        public string Source { get; set; }

        [JsonProperty("scopes")]
        public object Scopes { get; set; }

        [JsonProperty("text")]
        public string Text { get; set; }

        [JsonProperty("full_text")]
        public string FullText { get; set; }

        [JsonProperty("display_text_range")]
        public long[] DisplayTextRange { get; set; }

        [JsonProperty("place")]
        public object Place { get; set; }

        [JsonProperty("truncated")]
        public bool Truncated { get; set; }

        [JsonProperty("user")]
        public User User { get; set; }

        [JsonProperty("withheld_copyright")]
        public bool WithheldCopyright { get; set; }

        [JsonProperty("withheld_in_countries")]
        public object WithheldInCountries { get; set; }

        [JsonProperty("withheld_scope")]
        public string WithheldScope { get; set; }

        [JsonProperty("extended_entities")]
        public object ExtendedEntities { get; set; }

        [JsonProperty("extended_tweet")]
        public ExtendedTweet ExtendedTweet { get; set; }

        [JsonProperty("quoted_status_id")]
        public long QuotedStatusId { get; set; }

        [JsonProperty("quoted_status_id_str")]
        public string QuotedStatusIdStr { get; set; }

        [JsonProperty("quoted_status")]
        public object QuotedStatus { get; set; }
    }

    public partial class Entities
    {
        [JsonProperty("hashtags")]
        public Hashtag[] Hashtags { get; set; }

        [JsonProperty("media")]
        public Media[] Media { get; set; }

        [JsonProperty("urls")]
        public Url[] Urls { get; set; }

        [JsonProperty("user_mentions")]
        public UserMention[] UserMentions { get; set; }
    }

    public partial class Hashtag
    {
        [JsonProperty("indices")]
        public long[] Indices { get; set; }

        [JsonProperty("text")]
        public string Text { get; set; }
    }

    public partial class Media
    {
        [JsonProperty("indices")]
        public long[] Indices { get; set; }

        [JsonProperty("display_url")]
        public string DisplayUrl { get; set; }

        [JsonProperty("expanded_url")]
        public Uri ExpandedUrl { get; set; }

        [JsonProperty("url")]
        public Uri Url { get; set; }

        [JsonProperty("id")]
        public double Id { get; set; }

        [JsonProperty("id_str")]
        public string IdStr { get; set; }

        [JsonProperty("media_url")]
        public Uri MediaUrl { get; set; }

        [JsonProperty("media_url_https")]
        public Uri MediaUrlHttps { get; set; }

        [JsonProperty("source_status_id")]
        public long SourceStatusId { get; set; }

        [JsonProperty("source_status_id_str")]
        public string SourceStatusIdStr { get; set; }

        [JsonProperty("type")]
        public string Type { get; set; }

        [JsonProperty("sizes")]
        public Sizes Sizes { get; set; }

        [JsonProperty("video_info")]
        public VideoInfo VideoInfo { get; set; }
    }

    public partial class Sizes
    {
        [JsonProperty("thumb")]
        public Large Thumb { get; set; }

        [JsonProperty("large")]
        public Large Large { get; set; }

        [JsonProperty("medium")]
        public Large Medium { get; set; }

        [JsonProperty("small")]
        public Large Small { get; set; }
    }

    public partial class Large
    {
        [JsonProperty("w")]
        public long W { get; set; }

        [JsonProperty("h")]
        public long H { get; set; }

        [JsonProperty("resize")]
        public string Resize { get; set; }
    }

    public partial class VideoInfo
    {
        [JsonProperty("aspect_ratio")]
        public long[] AspectRatio { get; set; }

        [JsonProperty("duration_millis")]
        public long DurationMillis { get; set; }

        [JsonProperty("variants")]
        public Variant[] Variants { get; set; }
    }

    public partial class Variant
    {
        [JsonProperty("content_type")]
        public string ContentType { get; set; }

        [JsonProperty("bitrate")]
        public long Bitrate { get; set; }

        [JsonProperty("url")]
        public Uri Url { get; set; }
    }

    public partial class Url
    {
        [JsonProperty("indices")]
        public long[] Indices { get; set; }

        [JsonProperty("display_url")]
        public string DisplayUrl { get; set; }

        [JsonProperty("expanded_url")]
        public Uri ExpandedUrl { get; set; }

        [JsonProperty("url")]
        public Uri UrlUrl { get; set; }
    }

    public partial class UserMention
    {
        [JsonProperty("indices")]
        public long[] Indices { get; set; }

        [JsonProperty("id")]
        public long Id { get; set; }

        [JsonProperty("id_str")]
        public object IdStr { get; set; }

        [JsonProperty("name")]
        public string Name { get; set; }

        [JsonProperty("screen_name")]
        public string ScreenName { get; set; }
    }

    public partial class ExtendedTweet
    {
        [JsonProperty("full_text")]
        public string FullText { get; set; }

        [JsonProperty("display_text_range")]
        public long[] DisplayTextRange { get; set; }

        [JsonProperty("entities")]
        public Entities Entities { get; set; }

        [JsonProperty("extended_entities")]
        public ExtendedEntities ExtendedEntities { get; set; }
    }

    public partial class ExtendedEntities
    {
        [JsonProperty("media")]
        public Media[] Media { get; set; }
    }

    public partial class User
    {
        [JsonProperty("contributors_enabled")]
        public bool ContributorsEnabled { get; set; }

        [JsonProperty("created_at")]
        public string CreatedAt { get; set; }

        [JsonProperty("default_profile")]
        public bool DefaultProfile { get; set; }

        [JsonProperty("default_profile_image")]
        public bool DefaultProfileImage { get; set; }

        [JsonProperty("description")]
        public string Description { get; set; }

        [JsonProperty("email")]
        public string Email { get; set; }

        [JsonProperty("entities")]
        public object Entities { get; set; }

        [JsonProperty("favourites_count")]
        public long FavouritesCount { get; set; }

        [JsonProperty("follow_request_sent")]
        public bool FollowRequestSent { get; set; }

        [JsonProperty("following")]
        public bool Following { get; set; }

        [JsonProperty("followers_count")]
        public long FollowersCount { get; set; }

        [JsonProperty("friends_count")]
        public long FriendsCount { get; set; }

        [JsonProperty("geo_enabled")]
        public bool GeoEnabled { get; set; }

        [JsonProperty("id")]
        public double Id { get; set; }

        [JsonProperty("id_str")]
        public string IdStr { get; set; }

        [JsonProperty("is_translator")]
        public bool IsTranslator { get; set; }

        [JsonProperty("lang")]
        public string Lang { get; set; }

        [JsonProperty("listed_count")]
        public long ListedCount { get; set; }

        [JsonProperty("location")]
        public string Location { get; set; }

        [JsonProperty("name")]
        public string Name { get; set; }

        [JsonProperty("notifications")]
        public bool Notifications { get; set; }

        [JsonProperty("profile_background_color")]
        public string ProfileBackgroundColor { get; set; }

        [JsonProperty("profile_background_image_url")]
        public string ProfileBackgroundImageUrl { get; set; }

        [JsonProperty("profile_background_image_url_https")]
        public string ProfileBackgroundImageUrlHttps { get; set; }

        [JsonProperty("profile_background_tile")]
        public bool ProfileBackgroundTile { get; set; }

        [JsonProperty("profile_banner_url")]
        public Uri ProfileBannerUrl { get; set; }

        [JsonProperty("profile_image_url")]
        public Uri ProfileImageUrl { get; set; }

        [JsonProperty("profile_image_url_https")]
        public Uri ProfileImageUrlHttps { get; set; }

        [JsonProperty("profile_link_color")]
        public string ProfileLinkColor { get; set; }

        [JsonProperty("profile_sidebar_border_color")]
        public string ProfileSidebarBorderColor { get; set; }

        [JsonProperty("profile_sidebar_fill_color")]
        public string ProfileSidebarFillColor { get; set; }

        [JsonProperty("profile_text_color")]
        public object ProfileTextColor { get; set; }

        [JsonProperty("profile_use_background_image")]
        public bool ProfileUseBackgroundImage { get; set; }

        [JsonProperty("protected")]
        public bool Protected { get; set; }

        [JsonProperty("screen_name")]
        public string ScreenName { get; set; }

        [JsonProperty("show_all_inline_media")]
        public bool ShowAllInlineMedia { get; set; }

        [JsonProperty("status")]
        public object Status { get; set; }

        [JsonProperty("statuses_count")]
        public long StatusesCount { get; set; }

        [JsonProperty("time_zone")]
        public string TimeZone { get; set; }

        [JsonProperty("url")]
        public string Url { get; set; }

        [JsonProperty("utc_offset")]
        public long UtcOffset { get; set; }

        [JsonProperty("verified")]
        public bool Verified { get; set; }

        [JsonProperty("withheld_in_countries")]
        public object WithheldInCountries { get; set; }

        [JsonProperty("withheld_scope")]
        public string WithheldScope { get; set; }
    }
}
