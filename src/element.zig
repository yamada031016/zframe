//! This module provides structures and functions for representation of HTML elements.
const std = @import("std");
const Tag = @import("html.zig").Tag;

/// This function returns proper Element union.
pub fn createElement(comptime tagName: Tag) Element {
    return switch (tagName) {
        .img => Element{ .image = Image{} },
        .a => Element{ .hyperlink = HyperLink{} },
        .link => Element{ .link = Link{} },
        .meta => Element{ .meta = Meta{} },
        .form => Element{ .form = Form{} },
        .input => Element{ .input = Input{} },
        .col, .colgroup => Element{ .tablecol = TableCol{} },
        .th => Element{ .th = TableHead{} },
        .td => Element{ .td = TableData{} },
        .custom => Element{ .custom = Custom{} },
        else => Element{
            .plane = PlaneElement{
                .tag = tagName,
            },
        },
    };
}

/// This enum definites types of Element.
/// These value is used at Element union as key.
pub const ElementType = enum {
    plane,
    image,
    hyperlink,
    link,
    meta,
    form,
    input,
    tablecol,
    th,
    td,
    custom,
};

/// This union provides abstract interface for users
pub const Element = union(ElementType) {
    plane: PlaneElement,
    image: Image,
    hyperlink: HyperLink,
    link: Link,
    meta: Meta,
    form: Form,
    input: Input,
    tablecol: TableCol,
    th: TableHead,
    td: TableData,
    custom: Custom,

    const TemplateError = error{
        TemplateNotSupport,
        TemplateNotSetting,
    };

    pub const ElementError = TemplateError;

    pub fn getTagName(self: *const Element) []const u8 {
        switch (self.*) {
            .plane => |p| return p.tag.asText(),
            .hyperlink => return "a",
            .tablecol => return "col", // or "colgroup"
            else => return @tagName(self.*),
        }
    }

    pub fn getTemplate(self: *const Element) ElementError![]u8 {
        switch (self.*) {
            .plane => |*elem| return if (elem.template) |e| e else ElementError.TemplateNotSetting,
            .hyperlink => |*elem| return if (elem.template) |e| e else ElementError.TemplateNotSetting,
            .custom => |*elem| return if (elem.template) |e| e else ElementError.TemplateNotSetting,
            .th => |*elem| return if (elem.template) |e| e else ElementError.TemplateNotSetting,
            .td => |*elem| return if (elem.template) |e| e else ElementError.TemplateNotSetting,
            else => return ElementError.TemplateNotSupport,
        }
    }
};

// add functions for checking validation.

/// This structure represents Generic HTML Element such as h1, p, and so on.
pub const PlaneElement = struct {
    const Directionality = enum { leftToRight, RightToLeft, Auto };

    tag: Tag,
    template: ?[]u8 = null,

    accesskey: ?[]u8 = null,
    contenteditable: ?bool = null,
    dir: ?Directionality = null,
    draggable: ?bool = null,
    hidden: ?bool = null,
    itemprop: ?[]u8 = null,
    lang: ?[]u8 = null,
    role: ?[]u8 = null,
    slot: ?[]u8 = null,
    spellcheck: ?bool = null,
    style: ?[]u8 = null,
    title: ?[]u8 = null,
    translate: ?bool = null,
};

/// This structure represents image tag without any auto-optimization.
// add isValid() for check srcset, sizes...
pub const Image = struct {
    const Crossorigin = enum {
        anonymous,
        useCredentials,
    };

    const Decoding = enum {
        Sync,
        Async,
        Auto,
    };

    const fetchPriority = enum {
        high,
        low,
        auto,
    };

    const Loading = enum {
        eager,
        lazy,
    };

    const referrerPolicy = enum {
        noReferrer,
        noReferrerWhenDowngrade,
        origin,
        originWhenCrossOrigin,
        sameOrigin,
        strictOrigin,
        strictOriginWhenCrossOrigin,
        unsafeUrl,
    };

    src: ?[]u8 = null,
    alt: ?[]u8 = null,
    width: ?u16 = null,
    height: ?u16 = null,
    attributionsrc: ?[]u8 = null,
    crossorigin: ?Crossorigin = null,
    decoding: ?Decoding = null,
    elementtiming: ?[]u8 = null,
    fetchpriority: ?fetchPriority = null,
    ismap: ?bool = null,
    loading: ?Loading = null,
    referrerpolicy: ?referrerPolicy = null,
    sizes: ?[]u8 = null,
    srcset: ?[]u8 = null,
    usemap: ?[]u8 = null,
};

/// This structure represents anchor tag without any auto-optimization.
pub const HyperLink = struct {
    const referrerPolicy = enum {
        noReferrer,
        noReferrerWhenDowngrade,
        origin,
        originWhenCrossOrigin,
        sameOrigin,
        strictOrigin,
        strictOriginWhenCrossOrigin,
        unsafeUrl,
    };

    const Target = enum {
        self,
        blank,
        parent,
        top,
        unfencedTop,
    };
    const relValue = enum {
        alternate,
        author,
        bookmark,
        external,
        help,
        license,
        next,
        nofollow,
        noreferrer,
        noopener,
        prev,
        search,
        tag,
    };
    template: ?[]u8 = null,
    href: ?[]u8 = null,

    target: ?Target = null,
    download: ?[]u8 = null,
    rel: ?relValue = null,
    hreflang: ?[]u8 = null,
    ping: ?[]u8 = null,
    referrerpolicy: ?referrerPolicy = null,
    mimeType: ?[]u8 = null,
    attributionsrc: ?[]u8 = null,
};

/// This structure represents meta tag.
pub const Meta = struct {
    meta_type: ?MetaType = undefined,
    property: ?[]u8 = null,
    content: ?[]u8 = null,
    charset: ?[]u8 = null,

    pub const MetaType = enum {
        charset,

        description,
        viewport,
        keywords,
        property,
        twitter_card,
        twitter_site,
        twitter_creator,
        theme_color,

        pub fn asText(meta: *const MetaType) []const u8 {
            return switch (meta.*) {
                .charset => "charset",
                .description => "description",
                .viewport => "viewport",
                .keywords => "keywords",
                .property => "property",
                .twitter_card => "twitter_card",
                .twitter_site => "twitter_site",
                .twitter_creator => "twitter_creator",
                .theme_color => "theme_color",
            };
        }
    };
};

/// This structure represents link tag.
pub const Link = struct {
    // this attribute is required when rel="preload", optional when rel="modulepreload"
    const typeOfContent = enum {
        audio,
        document,
        embed,
        fetch,
        font,
        image,
        object,
        script,
        style,
        track,
        video,
        worker,
    };

    const Crossorigin = enum {
        anonymous,
        useCredentials,
    };

    const fetchPriority = enum {
        high,
        low,
        auto,
    };

    const referrerPolicy = enum {
        noReferrer,
        noReferrerWhenDowngrade,
        origin,
        originWhenCrossOrigin,
        unsafeUrl,
    };

    rel: ?[]u8 = null,
    href: ?[]u8 = null,

    as: ?[]u8 = null,
    blocking: ?[]u8 = null,
    crossorigin: ?Crossorigin = null,
    disabled: ?bool = null, // for rel="stylesheet" only
    fetchpriority: ?fetchPriority = null,
    hreflang: ?[]u8 = null,
    imagesizes: ?[]u8 = null, // for rel="preload" and as="image" only
    imagesrcset: ?[]u8 = null, // for rel="preload" and as="image" only
    integrity: ?[]u8 = null, // for rel="stylesheet" or "preload" or "modulepreload"
    media: ?[]u8 = null,
    referrerpolicy: ?referrerPolicy = null,
    sizes: ?[]u8 = null,
    title: ?[]u8 = null,
    type: ?typeOfContent = null,
};

/// This structure represents Web Components's custom element.
pub const Custom = struct {
    template: ?[]u8 = null,
};

pub const Form = struct {
    accept_charset: ?[]u8 = null,
    action: ?[]u8 = null,
    autocomplete: ?enum { on, off } = null,
    enctype: ?enum {
        application_x_www_form_urlencoded,
        multipart_form_data,
        text_plain,
    } = null,
    method: ?enum { dialog, get, post } = null,
    name: ?[]u8 = null,
    novalidate: ?bool = null,
    rel: ?enum {
        external,
        help,
        license,
        next,
        nofollow,
        noopener,
        noreferrer,
        opener,
        prev,
        search,
    } = null,
    target: ?enum {
        _blank,
        _self,
        _parent,
        _top,
    } = null,
};

pub const Input = struct {
    const InputType = enum {
        button,
        checkbox,
        color,
        date,
        datetime_local,
        email,
        file,
        hidden,
        image,
        month,
        number,
        password,
        radio,
        range,
        reset,
        search,
        submit,
        tel,
        text,
        time,
        url,
        week,
    };
    type: ?InputType = null,
    accept: ?[]u8 = null,
    alt: ?[]u8 = null,
    autocomplete: ?enum { on, off } = null,
    autofocus: ?bool = null,
    capture: ?enum { user, environment } = null,
    checked: ?bool = null,
    dirname: ?[]u8 = null,
    disabled: ?bool = null,
    form: ?[]u8 = null,
    formaction: ?[]u8 = null,
    formenctype: ?enum {
        application_x_www_form_urlencoded,
        multipart_form_data,
        text_plain,
    } = null,
    formmethod: ?enum { get, post } = null,
    formnovalidate: ?bool = null,
    formtarget: ?enum {
        _blank,
        _self,
        _parent,
        _top,
    } = null,
    height: ?u16 = null,
    list: ?[]u8 = null,
    max: ?u16 = null,
    maxlenght: ?u16 = null,
    min: ?u16 = null,
    minlenght: ?u16 = null,
    multiple: ?bool = null,
    name: ?[]u8 = null,
    pattern: ?[]u8 = null,
    placeholder: ?[]u8 = null,
    popovertarget: ?[]u8 = null,
    popovertargetaction: ?enum { hide, show, toggle } = null,
    readonly: ?bool = null,
    required: ?bool = null,
    size: ?u16 = null,
    src: ?[]u8 = null,
    step: ?u16 = null,
    value: ?[]u8 = null,
    width: ?u16 = null,
};

pub const TableCol = struct {
    span: ?u8 = null,
};

pub const TableHead = struct {
    template: ?[]u8 = null,
    abbr: ?[]u8 = null,
    colspan: ?u8 = null,
    headers: ?[]u8 = null,
    rowspan: ?u8 = null,
    scope: ?enum { row, col, rowgroup, colgroup } = null,
};

pub const TableData = struct {
    colspan: ?u8 = null,
    headers: ?[]u8 = null,
    rowspan: ?u8 = null,
    template: ?[]u8 = null,
};
