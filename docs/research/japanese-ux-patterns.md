# Japanese vs Western UI/UX Design Patterns

## Overview

This research documents key differences between Japanese and Western UI/UX design patterns for use in the Designer Agent. The goal is to provide structured, actionable guidelines that enable context-aware design decisions when building interfaces for Japanese or Western audiences.

**Scope:** 12 patterns across 4 categories covering visual design, information architecture, interaction design, and trust/credibility. Each pattern includes a comparative analysis, implementation guidelines with Design Token direction, and real-world examples.

**Designer Agent Usage:** The agent references patterns by ID (P-01 to P-12) and uses the Decision Matrix at the end to select appropriate defaults based on target audience. Implementation Guidelines provide Design Token-level direction without prescribing exact CSS values.

## Categories

### 1. Visual Design

#### P-01: Information Density (情報密度)

| Aspect | Japanese Pattern | Western Pattern |
|--------|-----------------|-----------------|
| Overview | High-density layouts showing comprehensive information upfront | Progressive disclosure with minimal initial content |

**Japanese Approach:**
- Display 20-30 interactive elements per viewport to satisfy holistic attention patterns
- Multiple content columns, banners, sidebars, and CTAs visible simultaneously
- Whitespace perceived as "samishii" (寂しい/lonely) and signals incomplete content
- Magazine-style layouts derived from print design traditions
- Users expect to scroll through entire pages before forming opinions

**Western Approach:**
- 5-10 key elements per viewport following "don't make me think" principle
- Progressive disclosure hides complexity behind dropdowns, tabs, or separate pages
- Generous whitespace signals sophistication and focus
- Grid-based layouts with clear visual breathing room
- Users expect to find key actions immediately without scrolling

**Implementation Guidelines:**
- spacing: compact (4-8px gaps) for JP vs relaxed (16-24px gaps) for Western
- grid-columns: 3-4 columns for JP vs 1-2 columns for Western content areas
- content-per-viewport: target 20-30 elements (JP) vs 5-10 elements (Western)
- sidebar: always-visible for JP vs collapsible/hidden for Western
- Bento-style modular blocks emerging as modern JP compromise

**Examples:**
- Japan: Yahoo! JAPAN homepage displays news, weather, shopping, mail, and dozens of service links on a single page. Rakuten Ichiba product pages show reviews, related items, seller info, and shipping details all at once. Rakuten tested cleaner designs but the dense version converted better.
- Western: Google.com uses a single search bar with vast whitespace. Stripe's marketing pages use one message per viewport with progressive scroll reveals.

#### P-02: Typography (タイポグラフィ)

| Aspect | Japanese Pattern | Western Pattern |
|--------|-----------------|-----------------|
| Overview | Multi-script complexity requiring larger sizes and alternative hierarchy signals | Single-script systems using size, weight, and case for hierarchy |

**Japanese Approach:**
- Four scripts in single sentences: hiragana, katakana, kanji, and Latin characters
- No italic or capitalization available for emphasis; rely on color, background, and borders
- Gothic (sans-serif) fonts for UI/headings; Mincho (serif) for body/long-form
- Larger base font sizes needed due to kanji complexity (minimum 16px)
- Fixed-pitch preferred for body text; proportional for UI elements
- Text can flow horizontally or vertically

**Western Approach:**
- Single Latin script with rich typographic tools (italic, bold, caps, small-caps)
- Size and weight alone create clear hierarchy
- Sans-serif dominant for UI; serif for editorial/long-form
- Smaller base sizes viable (14-16px body)
- Proportional pitch standard across all contexts

**Implementation Guidelines:**
- font-size-base: 16px minimum for JP (complex kanji legibility) vs 14px minimum for Western (note: modern design systems 2020s+ default to 16px, narrowing this gap)
- line-height: 1.8-2.0 for JP vs 1.5-1.6 for Western (CJK characters need more vertical space)
- letter-spacing: 0.05-0.1em for JP vs 0 for Western
- font-family: Noto Sans CJK JP / Hiragino Gothic for JP vs system sans-serif for Western
- emphasis-method: color + background-color + border for JP vs font-weight + font-style for Western
- text-align: justify for JP (no word spacing issues) vs left for Western

**Examples:**
- Japan: NHK News uses Hiragino Gothic with large font sizes and colored backgrounds to differentiate headline levels. Nikkei uses Mincho (serif) for article body with Gothic headings.
- Western: Medium.com uses font-size and weight alone for hierarchy. The New York Times uses serif for articles and sans-serif for navigation.

#### P-03: Color Palette (カラーパレット)

| Aspect | Japanese Pattern | Western Pattern |
|--------|-----------------|-----------------|
| Overview | Light tones, pastels, and vibrant accents with cultural color meanings | Muted neutrals with limited accent colors for contrast |

**Japanese Approach:**
- Light backgrounds: white, light gray, cream, soft pastels dominant
- Vibrant accent colors: red (prosperity, vitality), pink (seasonal/sakura), gold (quality)
- Seasonal color changes in banners, logos, and accent colors (sakura spring, fireworks summer)
- Kawaii aesthetic influences: soft pastels (baby pink, mint green, lavender, powder blue)
- Dark themes generally avoided; light tones preferred for trustworthiness
- Traditional color vocabulary: approximately 250 named colors in Japanese aesthetic tradition

**Western Approach:**
- Neutral backgrounds (white, gray) with 1-2 brand accent colors
- Muted, balanced color schemes prioritizing harmony and focus
- Color meanings differ: red signals danger/error, white signals purity
- Consistent brand palette year-round; seasonal changes are rare
- Dark mode widely adopted as user preference option
- Limited color palette for brand consistency

**Implementation Guidelines:**
- background-color: light pastels / cream for JP vs pure white / neutral gray for Western
- accent-primary: warm tones (red, orange, gold) for JP vs brand-specific for Western
- color-semantic: red as positive/prosperity (JP) vs red as error/danger (Western)
- seasonal-theming: implement seasonal palette swaps for JP vs static palette for Western
- dark-mode: optional/secondary for JP vs expected parity for Western
- palette-size: broader range (8-12 colors) for JP vs constrained (4-6 colors) for Western

**Examples:**
- Japan: Rakuten uses red extensively as primary brand color signaling prosperity. Sanrio's website uses soft pastels (pink, lavender, mint). Japanese convenience store apps (Lawson, FamilyMart) change seasonal colors.
- Western: Stripe uses a minimal palette of white, dark gray, and blue-purple. Airbnb uses white with a single coral accent color.

#### P-04: Visual Hierarchy (視覚的階層)

| Aspect | Japanese Pattern | Western Pattern |
|--------|-----------------|-----------------|
| Overview | Hierarchy through color, borders, and background fills due to script limitations | Hierarchy through size, weight, and whitespace |

**Japanese Approach:**
- Background color blocks and bordered sections create visual grouping
- Color-coded categories and labels for quick scanning of dense content
- Icon-heavy navigation to aid recognition in information-dense layouts
- Banner images and illustrated characters (mascots) guide attention
- "Ichimokuryouzen" (一目瞭然) principle: understand everything at a glance

**Western Approach:**
- Size contrast (headings 2-3x body size) as primary hierarchy tool
- Whitespace creates grouping and separation between content blocks
- Minimal decorative elements; typography carries hierarchy
- Photography over illustration for visual interest
- F-pattern and Z-pattern eye tracking guides layout

**Implementation Guidelines:**
- section-separation: background-color alternation + border for JP vs whitespace + subtle dividers for Western
- heading-style: colored background + icon for JP vs size + weight for Western
- grouping-method: bordered cards with color-coded headers for JP vs whitespace grouping for Western
- mascot/illustration: expected and trust-building for JP vs optional brand element for Western
- visual-weight: distribute evenly across viewport (JP) vs concentrate at top-left (Western)

**Examples:**
- Japan: Kakaku.com uses color-coded category tabs with bordered content blocks. Amazon Japan uses more color-coded badges and labels than Amazon US.
- Western: Apple.com uses massive typography and whitespace for hierarchy. Notion uses size and weight alone with minimal color.

### 2. Information Architecture (情報設計)

#### P-05: Navigation Patterns (ナビゲーション)

| Aspect | Japanese Pattern | Western Pattern |
|--------|-----------------|-----------------|
| Overview | Dense mega-menus showing full site structure at once | Simplified nav with progressive discovery of deeper pages |

**Japanese Approach:**
- Mega-menus exposing 2-3 levels of hierarchy simultaneously
- Multiple navigation zones: header, sidebar, footer, and in-page links
- Category-heavy navigation reflecting deep product/content taxonomies
- Users prefer scrolling over clicking to new pages for additional information
- Sticky headers common to maintain navigation during long scrolls
- Breadcrumb trails expected on all content pages

**Western Approach:**
- Hamburger menus or simple horizontal navigation with 5-7 top-level items
- Single navigation zone (header) with footer as secondary
- Flat navigation structures prioritizing search over browsing
- Click-through to dedicated pages for detailed content
- Minimal breadcrumbs; back button and search as primary wayfinding

**Implementation Guidelines:**
- nav-depth: 2-3 levels visible in mega-menu for JP vs 1 level with dropdowns for Western
- nav-zones: header + sidebar + footer (all active) for JP vs header primary for Western
- scroll-vs-click: favor long-scroll single pages for JP vs multi-page click-through for Western
- breadcrumbs: always visible for JP vs optional for Western
- sticky-header: required for JP vs recommended for Western
- footer-nav: comprehensive site map for JP vs minimal links for Western

**Examples:**
- Japan: Yahoo! JAPAN's mega-menu exposes dozens of service categories with icons. Rakuten's category navigation shows 3 levels of product taxonomy simultaneously.
- Western: Dropbox uses a simple 5-item horizontal nav. GitHub uses a hamburger menu on mobile with flat structure.

#### P-06: Content Strategy (コンテンツ戦略)

| Aspect | Japanese Pattern | Western Pattern |
|--------|-----------------|-----------------|
| Overview | Upfront comprehensive disclosure building trust through completeness | Progressive disclosure building engagement through curiosity |

**Japanese Approach:**
- All relevant information presented on a single page (specs, reviews, FAQs, shipping, returns)
- Detailed product descriptions with exhaustive specifications
- Formal, polite language (keigo) even in digital interfaces
- Information completeness signals reliability and thoroughness (Omotenashi spirit)
- FAQ sections prominent and comprehensive
- Long-form content preferred over summaries

**Western Approach:**
- Key information highlighted; details behind "Learn more" or expandable sections
- Concise product descriptions focused on benefits over specifications
- Casual, conversational tone building approachability
- Progressive disclosure builds engagement and reduces cognitive load
- FAQ minimized or replaced by chatbots/help centers
- Scannable content with bullet points and short paragraphs

**Implementation Guidelines:**
- content-disclosure: upfront/complete for JP vs progressive/staged for Western
- page-length: long-form single-page for JP vs paginated/tabbed for Western
- tone: formal/polite (desu-masu) for JP vs casual/conversational for Western
- spec-detail-level: exhaustive for JP vs highlights-only for Western
- faq-visibility: prominent on-page for JP vs help center link for Western
- content-density: high text-to-whitespace ratio for JP vs low ratio for Western

**Examples:**
- Japan: Amazon Japan product pages show significantly more detail than Amazon US. Tabelog (restaurant reviews) shows comprehensive menus, photos, maps, and reviews on single pages.
- Western: Basecamp uses benefit-focused headlines with minimal specs. Product Hunt shows brief descriptions with "Visit" CTAs.

#### P-07: Form Design (フォームデザイン)

| Aspect | Japanese Pattern | Western Pattern |
|--------|-----------------|-----------------|
| Overview | Multi-field forms with culturally specific inputs (furigana, postal code) | Minimal fields with autofill and social login shortcuts |

**Japanese Approach:**
- Name fields split into sei (姓/family) and mei (名/given) with mandatory furigana (フリガナ) fields
- Postal code field uses 〒 symbol prefix, split into 3+4 digit format (e.g., 〒153-0062)
- Address autofill from 7-digit postal code is a near-universal standard (YubinBango.js, AjaxZip3)
- Address order: large to small (prefecture, city, ward, street, building)
- Date fields labeled with 年/月/日 characters, not slash separators
- All fields clearly labeled; placeholder-only labels avoided

**Western Approach:**
- Single name field or first/last with no pronunciation guide needed
- ZIP/postal code as simple text input without symbol prefix
- Address autofill via Google Places API or similar geo-lookup
- Address order: small to large (street, city, state, ZIP)
- Date fields use locale-specific formats (MM/DD/YYYY or DD/MM/YYYY)
- Minimal fields; social login (Google, Apple) reduces form length

**Implementation Guidelines:**
- name-fields: sei + mei + furigana (katakana validated) for JP vs first + last for Western
- postal-code: 〒 prefix + 3-4 split input + auto address fill for JP vs single input for Western
- address-order: prefecture > city > street > building for JP vs street > city > state > zip for Western
- date-format: YYYY年MM月DD日 selectors for JP vs locale-dependent for Western
- field-count: more fields accepted (completeness = trust) for JP vs minimum viable for Western
- autofill-library: YubinBango.js / AjaxZip3 for JP vs Google Places for Western

**Examples:**
- Japan: Rakuten registration requires furigana, split postal code, and full address hierarchy. Every major Japanese e-commerce site auto-fills address from postal code.
- Western: Stripe Checkout uses a single-page form with minimal fields. Shopify uses Google Places for one-tap address entry.

### 3. Interaction Design (インタラクションデザイン)

#### P-08: Microinteractions (マイクロインタラクション)

| Aspect | Japanese Pattern | Western Pattern |
|--------|-----------------|-----------------|
| Overview | Contextual, guided interactions with character-driven feedback | Subtle, physics-based animations with minimal visual noise |

**Japanese Approach:**
- Mascot characters (yuru-chara) provide feedback and guide user flows
- Pulsing and attention-drawing animations to surface features (e.g., Mercari's search bar pulse)
- Contextual permission requests tied to value demonstration (not on first launch)
- Sound effects and haptic feedback more common in apps
- Elaborate loading animations and transition sequences
- Confirmation dialogs for important actions with detailed explanations

**Western Approach:**
- Physics-based subtle animations (spring, ease-out) for state changes
- Skeleton screens and shimmer loading states
- System-level permission prompts on first launch
- Minimal sound; haptics only for key actions
- Quick transitions prioritizing speed over ceremony
- Inline validation and progressive error display

**Implementation Guidelines:**
- feedback-style: mascot/character animation for JP vs subtle motion/opacity for Western
- loading-state: illustrated/branded animation for JP vs skeleton/shimmer for Western
- permission-timing: contextual after value shown for JP vs onboarding for Western
- confirmation-dialogs: verbose with detail for JP vs concise for Western
- animation-duration: longer, ceremonial (300-500ms) for JP vs snappy (150-300ms) for Western
- sound-design: expected in apps for JP vs silent default for Western

**Examples:**
- Japan: Mercari uses pulsing microinteractions on saved searches and contextual push notification prompts. LINE uses sticker-based reactions and elaborate animated transitions between screens.
- Western: iOS uses spring physics for all transitions. Slack uses subtle animations for message delivery confirmation.

#### P-09: Mobile-First Approach (モバイルファースト)

| Aspect | Japanese Pattern | Western Pattern |
|--------|-----------------|-----------------|
| Overview | Super-app ecosystems with deep service integration on mobile | Single-purpose apps with cross-app deep linking |

**Japanese Approach:**
- Super-app model: LINE integrates messaging, payments, shopping, news, and games
- Tab-bar navigation with 4-5 primary services
- Dense but well-organized content in scrollable cards
- QR code integration for payments and real-world interaction (ubiquitous)
- Platform-adaptive design: consistent behavior across iOS/Android while respecting platform conventions
- Feature discovery through notification dots and badges

**Western Approach:**
- Single-purpose apps focused on one core function
- Bottom navigation with 3-5 tabs following Material Design / HIG
- Card-based UI with generous spacing
- NFC/tap-to-pay primary; QR codes secondary
- Platform-native design following iOS HIG or Material Design strictly
- Feature discovery through onboarding tours and tooltips

**Implementation Guidelines:**
- app-scope: multi-service super-app for JP vs single-purpose for Western
- nav-pattern: tab-bar with 4-5 services for JP vs bottom-nav with 3-5 sections for Western
- payment-integration: QR code primary for JP vs NFC/tap primary for Western
- content-cards: compact with dense info for JP vs spacious with summary for Western
- platform-strategy: hybrid/cross-platform for JP vs platform-native for Western
- discovery-mechanism: notification badges for JP vs onboarding tours for Western

**Examples:**
- Japan: LINE encompasses messaging, LINE Pay, LINE Shopping, LINE News, and LINE Games in one app. PayPay uses QR code scanning as the primary payment interface.
- Western: Instagram focuses solely on photo/video sharing. Apple Pay uses NFC for tap-to-pay without QR codes.

### 4. Trust & Credibility (信頼性)

#### P-10: Trust Signals (信頼性表現)

| Aspect | Japanese Pattern | Western Pattern |
|--------|-----------------|-----------------|
| Overview | Comprehensive visible trust infrastructure with multiple signal types | Minimalist trust signals relying on brand reputation and clean design |

**Japanese Approach:**
- SSL/security badges prominently displayed, often multiple badges per page
- Company information (運営者情報) detailed and easily accessible
- Operating license and business registration numbers shown
- Physical office address and phone numbers prominently displayed
- Staff photos and company history build personal trust
- Detailed return/refund policies shown upfront, not hidden in footer links

**Western Approach:**
- Clean, professional design itself signals trustworthiness
- SSL padlock sufficient; additional badges used sparingly (3-5 max)
- Company info in footer or About page
- Trust through brand recognition and design quality
- Testimonial quotes and logos of known clients
- Policies accessible but not prominently displayed

**Implementation Guidelines:**
- badge-count: 5-8 visible trust badges for JP vs 2-3 for Western
- company-info: dedicated visible section with address/phone for JP vs footer link for Western
- policy-display: upfront on product/checkout pages for JP vs footer links for Western
- certification-display: business registration, industry licenses for JP vs optional for Western
- personal-touch: staff photos, founder message for JP vs brand-focused for Western
- contact-accessibility: phone number + form + chat for JP vs form + chat for Western

**Examples:**
- Japan: Rakuten displays SSL badges, seller ratings, return policies, and company registration on every product page. Japanese bank websites show multiple security certifications prominently.
- Western: Stripe's clean design and brand reputation serve as primary trust signals. Shopify shows a small "Powered by Shopify" badge and SSL lock.

#### P-11: Social Proof (ソーシャルプルーフ)

| Aspect | Japanese Pattern | Western Pattern |
|--------|-----------------|-----------------|
| Overview | Detailed, quantitative review systems with ranking culture | Star ratings and curated testimonials |

**Japanese Approach:**
- Detailed review systems with multiple rating dimensions (e.g., Tabelog: food, service, atmosphere)
- Ranking culture: top-10 lists, bestseller rankings, popularity indices prominent
- Review volume as trust signal (quantity matters as much as quality)
- Real-time purchase/booking activity displayed ("X people viewing now")
- User-generated photos heavily featured alongside reviews
- Point systems and loyalty program status as social proof

**Western Approach:**
- Aggregate star ratings (1-5) as primary social proof
- Curated testimonials from notable customers or publications
- "As seen in" media logos for credibility
- Review helpfulness voting (was this review helpful?)
- Influencer partnerships and social media follower counts
- Case studies and ROI metrics for B2B

**Implementation Guidelines:**
- rating-system: multi-dimensional scores for JP vs single aggregate star for Western
- ranking-display: prominent bestseller/popularity lists for JP vs optional for Western
- review-detail: volume + multi-criteria + photos for JP vs star + text summary for Western
- real-time-proof: "X people viewing/buying" for JP vs optional urgency signals for Western
- loyalty-display: point balance and tier status visible for JP vs minimal for Western
- proof-placement: on product listings and search results for JP vs product detail pages for Western

**Examples:**
- Japan: Tabelog rates restaurants on food/service/atmosphere with decimal precision (e.g., 3.72). Amazon Japan prominently shows bestseller rankings and review counts. Rakuten displays point earnings on every product.
- Western: Amazon US uses aggregate star ratings and "Amazon's Choice" badges. G2 uses star ratings with text reviews for SaaS products.

#### P-12: Compliance Display (法令遵守表示)

| Aspect | Japanese Pattern | Western Pattern |
|--------|-----------------|-----------------|
| Overview | Detailed legal/regulatory information displayed prominently | Compliance handled through policy pages and cookie banners |

**Japanese Approach:**
- Tokushoho (特定商取引法に基づく表記) legally required on all e-commerce sites
- Privacy policy links prominent, often in main navigation
- Age verification gates with clear legal basis explanation
- Detailed terms displayed during checkout, not just linked
- Company registration (法人番号) and industry certifications shown
- JIS compliance and accessibility statements increasingly common

**Western Approach:**
- GDPR/CCPA cookie consent banners as primary compliance UI
- Privacy policy and Terms of Service as footer links
- Minimal legal text during checkout flow to reduce friction
- Compliance badges (PCI DSS, SOC 2) for B2B contexts
- Accessibility statements growing but not yet universal
- Legal disclaimers in small print

**Implementation Guidelines:**
- legal-display: prominent dedicated section for JP vs footer links for Western
- checkout-legal: inline terms display for JP vs checkbox + link for Western
- privacy-nav: main navigation or header for JP vs footer for Western
- business-registration: visible on every page for JP vs About page for Western
- compliance-badges: industry-specific certifications displayed for JP vs PCI/SOC for Western B2B
- age-verification: detailed legal explanation for JP vs simple gate for Western

**Examples:**
- Japan: Every Japanese e-commerce site has a "特定商取引法に基づく表記" page linked from the footer and often from product pages. Rakuten and Amazon Japan display seller business registration details.
- Western: EU sites display GDPR cookie consent banners. Shopify stores link to policies in the footer with minimal visibility.

## Designer Agent Prompt Reference

### Decision Matrix

| Pattern ID | Category | JP Priority | Western Priority | Key Difference | Use JP When |
|------------|----------|-------------|-----------------|----------------|-------------|
| P-01 | Visual Design | High | Low | 20-30 vs 5-10 elements per viewport | Page serves as portal or landing with 15+ content items |
| P-02 | Visual Design | High | Medium | Multi-script hierarchy vs size/weight hierarchy | Interface includes CJK text content |
| P-03 | Visual Design | Medium | Medium | Light/pastel vs muted neutral palettes | Seasonal theming or cultural resonance needed |
| P-04 | Visual Design | High | Medium | Color/border vs whitespace hierarchy | Dense content requires clear visual grouping |
| P-05 | Info Architecture | High | Low | Mega-menu vs simplified nav | Site has deep content taxonomy (50+ categories) |
| P-06 | Info Architecture | High | Medium | Upfront disclosure vs progressive disclosure | User trust depends on information completeness |
| P-07 | Info Architecture | High | Medium | Furigana + postal autofill vs minimal forms | Forms collect Japanese name/address data |
| P-08 | Interaction | Medium | Medium | Mascot/guided vs subtle/physics-based | Brand uses character-driven communication |
| P-09 | Interaction | High | High | Super-app vs single-purpose | Mobile platform with multiple integrated services |
| P-10 | Trust | High | Low | Multi-badge visible vs clean design trust | E-commerce or financial services targeting JP market |
| P-11 | Trust | High | Medium | Multi-dimensional ranking vs star ratings | Product comparison and purchase decisions |
| P-12 | Trust | High | Low | Prominent legal display vs footer links | Japanese regulatory requirements apply (Tokushoho) |

### Quick Reference

- **P-01 Information Density:** JP=compact spacing, 20-30 elements/viewport; Western=relaxed spacing, 5-10 elements/viewport
- **P-02 Typography:** JP=Gothic/Mincho, 16px+ base, line-height 1.8-2.0, color emphasis; Western=sans/serif, 14px+ base, line-height 1.5-1.6, weight emphasis
- **P-03 Color Palette:** JP=light pastels, warm accents, seasonal; Western=neutral base, brand accent, static
- **P-04 Visual Hierarchy:** JP=color blocks + borders + icons; Western=size + weight + whitespace
- **P-05 Navigation:** JP=mega-menu, 2-3 levels, sticky; Western=flat nav, 1 level, hamburger mobile
- **P-06 Content Strategy:** JP=upfront complete, formal tone; Western=progressive, casual tone
- **P-07 Form Design:** JP=furigana + postal autofill + split fields; Western=minimal fields + social login
- **P-08 Microinteractions:** JP=mascot + contextual + ceremonial; Western=subtle + physics-based + snappy
- **P-09 Mobile-First:** JP=super-app + QR pay + dense cards; Western=single-purpose + NFC + spacious cards
- **P-10 Trust Signals:** JP=multi-badge + company info + phone; Western=clean design + brand + minimal badges
- **P-11 Social Proof:** JP=multi-dimensional ratings + rankings; Western=star ratings + testimonials
- **P-12 Compliance Display:** JP=prominent Tokushoho + inline terms; Western=cookie banner + footer links

## 5. AI-Generated UI Review (P-13〜P-17)

AI生成UIに特有のレビュー観点。文化パターン（P-01〜P-12）とは独立に、AI生成物の品質を引き上げる。

### P-13: Priority Focus (優先順位のメリハリ)

AI生成UIは要素を均等に配置しがちで、画面の「主役」が不明瞭になる。

| Aspect | Check |
|--------|-------|
| Hero Element | 画面に1つの明確な主役があるか |
| Visual Weight | 主役以外の要素は視覚的に控えめか |
| Action Priority | CTAボタンが1つに絞られているか |

### P-14: Context-Driven Design (業務文脈設計)

UIパターンの機械的寄せ集め（テンプレ感）を排除し、業務フローから設計されているかを検証。

| Aspect | Check |
|--------|-------|
| Workflow Fit | UIがユーザーの実際の業務フローに沿っているか |
| Domain Language | ドメイン固有の用語・概念がUIに反映されているか |
| Template Smell | 汎用ダッシュボードテンプレートそのままになっていないか |

### P-15: Color Role Separation (色の役割分離)

P-03 (Color Palette) の上位チェック。同じ色に複数の意味を持たせていないかを検証。

| Role | Purpose | Example |
|------|---------|---------|
| Brand | ブランドアイデンティティ | ロゴ、ヘッダー |
| Action | 操作可能な要素 | ボタン、リンク |
| State | 状態表示 | 成功(緑)、エラー(赤) |
| Warning | 注意喚起 | アラート、バッジ |

NG: 同じ青をリンクにもブランド背景にも使用。NG: 赤をエラーとセール価格の両方に使用。

### P-16: Real Data Resilience (実運用データ耐性)

モックデータでは美しいが実データで崩れるUIを検出。

| Edge Case | Check |
|-----------|-------|
| Long Text | 100文字超のタイトル、3行以上の説明文で崩れないか |
| Zero Items | データ0件時に空状態UIが表示されるか |
| Outliers | 異常に大きい数値、極端に長いユーザー名で崩れないか |
| Duplicates | 同一データが複数表示されても区別できるか |
| Missing Values | 画像なし、説明なし、日付なしでも破綻しないか |

### P-17: Ruthless Elimination (削ぎ落とし)

AI生成UIは装飾過多になりやすい。すべての要素が「ユーザーの今の作業に必要か」で検証。

| Aspect | Check |
|--------|-------|
| Decoration | グラデーション、影、角丸が目的なく使われていないか |
| Information | ユーザーが今必要としない情報が表示されていないか |
| Chrome | UIフレーム（ヘッダー/サイドバー/フッター）がコンテンツより目立っていないか |

## Sources

1. Nisbett, R.E. & Miyamoto, Y. (2005). "The influence of culture: holistic versus analytic perception." *Trends in Cognitive Sciences*, 9(10), 467-473.
2. Hayataki, M. "Japanese Web Typography: Anatomy and Best Practices." *Medium*.
3. iCrossing Japan. "Japanese UX Patterns and Metrics to Optimize Trust, Performance."
4. UX Design Newsletter. "The deeper meaning behind Japan's unique UX design culture." *uxdesign.cc*.
5. Amayadoring. "Japanese Web Form: Common Fields and Practices."
6. Spectrum Tokyo. "Understanding UX in Japan: A Japanese Perspective."
7. iCrossing Japan. "Japanese Web Design in 2025: Still Quirky, but More Modernized."
8. Disrupting Japan. "The lies, myths, and secrets of Japanese UI design."
9. Design Yokocho. "8 Classic Japanese Color Palettes."
10. Mercari Engineering Blog. "The Story Behind Mercari Design System Rebuild." / "Supercharging User Engagement."
