//
//  ContentItem.swift
//  BareKit
//
//  Created by Kiarash Asar on 11/3/25.
//

import Foundation

/// Represents a metric item for engagement display
public struct MetricItem: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public let count: String
    public let iconName: String // SF Symbol name

    public init(
        id: UUID = UUID(),
        count: String,
        iconName: String
    ) {
        self.id = id
        self.count = count
        self.iconName = iconName
    }
}

/// Represents a content item displayed in the grid
public struct ContentItem: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let thumbnailName: String // System image name or asset name (fallback)
    public let title: String
    public let createdDate: Date

    // Post teardown data (from database)
    public let originalURL: URL?
    public let imageUrl: String?
    public let engagementMetrics: [MetricItem]?
    public let viralStatus: String?
    public let authorHandle: String?
    public let summary: String?
    public let audioTranscription: String?
    public let visualTranscription: String?
    public let userResearchAnswer: String?
    public let commentsAnalysis: String?

    public init(
        id: UUID = UUID(),
        thumbnailName: String,
        title: String,
        createdDate: Date = Date(),
        originalURL: URL? = nil,
        imageUrl: String? = nil,
        engagementMetrics: [MetricItem]? = nil,
        viralStatus: String? = nil,
        authorHandle: String? = nil,
        summary: String? = nil,
        audioTranscription: String? = nil,
        visualTranscription: String? = nil,
        userResearchAnswer: String? = nil,
        commentsAnalysis: String? = nil
    ) {
        self.id = id
        self.thumbnailName = thumbnailName
        self.title = title
        self.createdDate = createdDate
        self.originalURL = originalURL
        self.imageUrl = imageUrl
        self.engagementMetrics = engagementMetrics
        self.viralStatus = viralStatus
        self.authorHandle = authorHandle
        self.summary = summary
        self.audioTranscription = audioTranscription
        self.visualTranscription = visualTranscription
        self.userResearchAnswer = userResearchAnswer
        self.commentsAnalysis = commentsAnalysis
    }
}

// MARK: - Sample Data
extension ContentItem {
    public static let sampleData: [ContentItem] = [
        ContentItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            thumbnailName: "photo",
            title: "Viral Recipe Post",
            createdDate: Date().addingTimeInterval(-86400 * 2),
            engagementMetrics: [
                MetricItem(count: "129k", iconName: "eye.fill"),
                MetricItem(count: "2.3k", iconName: "heart.fill"),
                MetricItem(count: "822", iconName: "bubble.left.fill")
            ],
            viralStatus: "Viral",
            authorHandle: "@michael_wiggly_recipes",
            summary: "This post features a quick and easy pasta recipe that went viral due to its simplicity and visual appeal. The creator demonstrates a 15-minute meal prep technique that resonated with busy home cooks.",
            audioTranscription: "Hey everyone, today I'm showing you the easiest pasta recipe you'll ever make. Start with your favorite pasta, cook it al dente. While that's cooking, grab some cherry tomatoes, garlic, and olive oil. Once the pasta is done, toss everything together with some fresh basil and parmesan. That's it! Restaurant quality in 15 minutes.",
            visualTranscription: "🍝 15-Minute Pasta Magic ✨\n\nThe easiest dinner recipe you'll ever make! Perfect for busy weeknights when you want something delicious without spending hours in the kitchen.\n\n#pasta #quickrecipes #easymeals #homecooking #foodie #viral",
            userResearchAnswer: "Validates that a 15-minute cherry tomato pasta hits the sweet spot of speed + fresh flavor, giving researchers a proven blueprint for quick dinner ideas.",
            commentsAnalysis: "Comments are overwhelmingly positive with users praising the simplicity and taste. Many viewers mentioned trying the recipe and sharing their results. Common themes include appreciation for quick meal ideas, requests for variations, and questions about ingredient substitutions."
        ),

        ContentItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            thumbnailName: "play.circle.fill",
            title: "AI Product Launch Breakdown",
            createdDate: Date().addingTimeInterval(-86400 * 5),
            engagementMetrics: [
                MetricItem(count: "87k", iconName: "eye.fill"),
                MetricItem(count: "5.1k", iconName: "heart.fill"),
                MetricItem(count: "1.2k", iconName: "bubble.left.fill")
            ],
            viralStatus: "Trending",
            authorHandle: "@tech_insider_daily",
            summary: "A comprehensive analysis of the latest AI product launch, breaking down the key features, market positioning, and potential impact on the industry. The video provides expert commentary on the technology stack and business strategy.",
            audioTranscription: "So today we're diving deep into this massive AI product launch. First, let's talk about the core technology - they're using a transformer-based architecture with some interesting modifications for latency reduction. The pricing strategy is aggressive, clearly targeting enterprise customers. What's fascinating is how they've positioned this against existing solutions. They're not just competing on features, but on the entire developer experience. The API design is clean, the documentation is solid, and they've built integrations for all major platforms from day one. This is how you launch a developer product in 2025.",
            visualTranscription: "🚀 Major AI Product Launch Analysis\n\nBreaking down everything you need to know about today's announcement. This is a game-changer for the industry.\n\nKey takeaways:\n- Revolutionary architecture\n- Enterprise-first approach\n- Competitive pricing\n\n#AI #tech #productlaunch #startup #innovation",
            userResearchAnswer: "Clarifies that the launch differentiates via latency-optimized transformers, enterprise-first pricing, and day-one integrations—precisely the intel product researchers need.",
            commentsAnalysis: "The tech community is highly engaged with this analysis. Comments show a mix of excitement and skepticism about the claims. Several industry professionals are sharing their own experiences with similar tools. Questions about pricing, availability, and technical implementation details dominate the discussion. Some concerns about vendor lock-in and data privacy were raised."
        ),

        ContentItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            thumbnailName: "figure.walk",
            title: "Morning Routine Transformation",
            createdDate: Date().addingTimeInterval(-86400 * 7),
            engagementMetrics: [
                MetricItem(count: "234k", iconName: "eye.fill"),
                MetricItem(count: "12k", iconName: "heart.fill"),
                MetricItem(count: "2.8k", iconName: "bubble.left.fill")
            ],
            viralStatus: "Viral",
            authorHandle: "@wellness_with_sarah",
            summary: "A lifestyle influencer shares her complete morning routine that helped her increase productivity and reduce anxiety. The routine includes specific timing, activities, and mindfulness practices backed by research.",
            audioTranscription: "I want to share the morning routine that completely changed my life. I wake up at 5:30 AM, no phone for the first hour. First thing, I drink a full glass of water with lemon. Then 20 minutes of meditation using the Headspace app. After that, I do a quick 15-minute workout - nothing crazy, just some yoga stretches and light cardio. Then I journal for 10 minutes, focusing on gratitude and setting intentions for the day. Finally, I have a healthy breakfast - usually oatmeal with berries and nuts. By 7 AM, I've already accomplished so much and I feel energized for the entire day. The key is consistency. It took me 3 weeks to build this habit, but now I can't imagine starting my day any other way.",
            visualTranscription: "☀️ My 5:30 AM Morning Routine\n\nThis transformed everything - my productivity, my mood, my energy levels. If you're struggling with morning motivation, try this!\n\n🌅 Wake up: 5:30 AM\n💧 Hydration first\n🧘‍♀️ 20 min meditation\n🏃‍♀️ 15 min workout\n📝 Gratitude journaling\n🥣 Healthy breakfast\n\n#morningroutine #productivity #wellness #selfcare #motivation #healthylifestyle",
            userResearchAnswer: "Shows that a 5:30 AM stack of hydration, meditation, light movement, journaling, and balanced breakfast is the repeatable playbook for higher energy mornings.",
            commentsAnalysis: "Overwhelmingly positive response with thousands sharing their own morning routine variations. Many appreciate the realistic timing and achievable goals. Common questions about handling different work schedules and family responsibilities. Some debate about the optimal wake-up time. Several users report back after trying the routine for a week with positive results."
        ),

        ContentItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            thumbnailName: "cart.fill",
            title: "Amazon Prime Day Deals Guide",
            createdDate: Date().addingTimeInterval(-86400),
            engagementMetrics: [
                MetricItem(count: "156k", iconName: "eye.fill"),
                MetricItem(count: "8.4k", iconName: "heart.fill"),
                MetricItem(count: "1.5k", iconName: "bubble.left.fill")
            ],
            viralStatus: "Trending",
            authorHandle: "@deal_hunter_pro",
            summary: "A curated list of the best Prime Day deals across electronics, home goods, and fashion. The creator provides price history analysis and recommendations on which deals are truly worth buying.",
            audioTranscription: "Alright, Prime Day is here and I've been tracking prices for months. Let me save you time and money. For tech, the Echo Dot is at an all-time low of $22 - that's 60% off, absolute steal. The Fire TV Stick 4K is also incredible at $25. For home, the Instant Pot Duo is $49, normally $120. Kitchen essentials are heavily discounted. Fashion-wise, the Levi's jeans are 40% off across most styles. My pro tip: use the CamelCamelCamel price tracker to verify these are actually good deals. Most importantly, don't buy something just because it's on sale. Stick to your list. I'll be updating this throughout the day with lightning deals.",
            visualTranscription: "🔥 PRIME DAY DEALS 2025\n\nI tracked prices for MONTHS to bring you only the REAL deals. Save this for later!\n\n✅ Echo Dot: $22 (60% off)\n✅ Fire TV 4K: $25\n✅ Instant Pot: $49\n✅ Levi's: 40% off\n\nMore deals in comments! 👇\n\n#primeday #amazon #deals #shopping #savings #amazonfinds",
            userResearchAnswer: "Provides a vetted shortlist of historically low Prime Day offers and the methodology (CamelCamelCamel + strict lists) for anyone researching smart shopping moves.",
            commentsAnalysis: "High engagement with users sharing additional deals they found and asking for recommendations in specific categories. Many thankful comments for the price tracking effort. Some discussion about Prime membership value. Several users creating shopping lists based on the recommendations. Requests for deals in specific categories like baby products, gaming, and fitness equipment."
        ),

        ContentItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
            thumbnailName: "house.fill",
            title: "Apartment Tour on a Budget",
            createdDate: Date().addingTimeInterval(-86400 * 10),
            engagementMetrics: [
                MetricItem(count: "445k", iconName: "eye.fill"),
                MetricItem(count: "28k", iconName: "heart.fill"),
                MetricItem(count: "3.2k", iconName: "bubble.left.fill")
            ],
            viralStatus: "Viral",
            authorHandle: "@minimal_living_alex",
            summary: "A minimalist apartment tour showcasing how to create a stylish living space on a limited budget. Features IKEA hacks, thrift store finds, and DIY projects. Emphasis on functionality and aesthetic appeal without overspending.",
            audioTranscription: "Welcome to my 600 square foot apartment! I decorated this entire place for under $3000. Let me show you how. The living room couch is from IKEA, but I upgraded it with custom legs from Etsy - total cost $550. The coffee table is actually a DIY project, made from reclaimed wood and hairpin legs, cost me $80. All the plants are from local nurseries, much cheaper than trendy plant shops. The bedroom features a platform bed frame I built myself following YouTube tutorials. The artwork throughout is a mix of Etsy prints and my own photography. The key to making a small space work is vertical storage and multi-functional furniture. Everything here has a purpose. The dining table folds down when I need more space. The ottoman has hidden storage. Small space living is all about being intentional with every piece you bring in.",
            visualTranscription: "🏠 Studio Apartment Tour - $3K Budget\n\nProof you don't need to spend a fortune to create a beautiful home. Every piece was carefully chosen for function AND style.\n\n💰 Total budget: $3,000\n📐 Space: 600 sq ft\n🛠️ 60% DIY projects\n♻️ 40% secondhand finds\n\nFull links in my bio!\n\n#apartmenttour #budgetfriendly #minimalism #interiordesign #smallspaceliving #ikea",
            userResearchAnswer: "Demonstrates that mixing IKEA staples, reclaimed DIY builds, and secondhand finds can dress a 600 sq ft apartment for $3K while maximizing hidden storage.",
            commentsAnalysis: "Extremely popular with young renters and first-time apartment dwellers. Many requesting links to specific furniture pieces and DIY tutorials. Questions about measurements and how items fit in the space. Appreciation for realistic budget expectations. Several comments from people inspired to redecorate their own spaces. Requests for a follow-up video with detailed DIY instructions."
        ),

        ContentItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
            thumbnailName: "dumbbell.fill",
            title: "30-Day Fitness Challenge Results",
            createdDate: Date().addingTimeInterval(-86400 * 3),
            engagementMetrics: [
                MetricItem(count: "198k", iconName: "eye.fill"),
                MetricItem(count: "15k", iconName: "heart.fill"),
                MetricItem(count: "1.9k", iconName: "bubble.left.fill")
            ],
            authorHandle: "@fit_journey_mike",
            summary: "Documenting the complete results of a 30-day fitness challenge with before/after photos, workout routines, and honest reflections on the process. Includes discussion of diet changes, workout consistency, and mental health benefits.",
            audioTranscription: "Today marks day 30 of my fitness challenge and I want to be completely transparent with you. I didn't get ripped abs. I didn't lose 30 pounds. But here's what I did gain: consistency. I worked out 28 out of 30 days. I learned to meal prep. I sleep better. I have more energy. The physical changes are there - I lost 8 pounds, gained visible muscle definition, and my endurance has doubled. But the mental changes are even bigger. I proved to myself that I can commit to something and follow through. My workout routine was simple: 30 minutes a day, mix of cardio and bodyweight exercises. No gym required. The hardest part wasn't the workouts, it was building the habit. Days 1-10 were brutal. Days 11-20 got easier. Days 21-30, I actually looked forward to it. If you're thinking about starting your own challenge, just start. Don't wait for Monday. Don't wait for the perfect plan. Just begin.",
            visualTranscription: "✅ 30-DAY FITNESS CHALLENGE: COMPLETE\n\nReal results, honest thoughts, no BS.\n\n📊 Results:\n- 8 lbs lost\n- Muscle definition +40%\n- Energy levels ⬆️\n- Consistency: 28/30 days\n\nThe journey > the destination\n\n#fitness #transformation #30daychallenge #workout #motivation #fitnessmotivation",
            userResearchAnswer: "Shows that 30-minute daily bodyweight sessions plus simple meal prep drive sustainable gains—the key insight for anyone researching realistic fitness challenges.",
            commentsAnalysis: "Inspiring comments from people starting their own fitness journeys. Many appreciate the honest, realistic approach rather than exaggerated transformation claims. Questions about specific exercises, diet plans, and how to stay motivated. Several people sharing their own progress. Supportive community atmosphere with users encouraging each other."
        ),

        ContentItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!,
            thumbnailName: "photo.fill",
            title: "iPhone Photography Tips",
            createdDate: Date().addingTimeInterval(-86400 * 14),
            engagementMetrics: [
                MetricItem(count: "92k", iconName: "eye.fill"),
                MetricItem(count: "6.7k", iconName: "heart.fill"),
                MetricItem(count: "890", iconName: "bubble.left.fill")
            ],
            authorHandle: "@mobile_photo_pro",
            summary: "Professional photographer shares advanced iPhone photography techniques that anyone can use. Covers composition, lighting, editing apps, and how to maximize the iPhone camera's capabilities.",
            audioTranscription: "You don't need a fancy camera to take amazing photos. Your iPhone is more powerful than you think. Here are my top 5 tips. One, use portrait mode but not just for people - it works great for food, products, and nature shots. Two, never use digital zoom, always move closer physically. Three, tap to focus and then adjust exposure by sliding up or down. Four, shoot in RAW format if your iPhone supports it, gives you more editing flexibility. Five, learn basic editing in Lightroom Mobile. Just adjusting exposure, shadows, and highlights can transform a photo. The most important thing is composition. Use the rule of thirds. Look for leading lines. Find interesting angles. The best camera is the one you have with you, and that's usually your phone.",
            visualTranscription: "📸 iPhone Photography Secrets\n\nStop saying you need a better camera! Master these 5 techniques and transform your photos.\n\n🎯 Portrait mode for everything\n🚫 Never digital zoom\n💡 Master tap-to-focus\n📁 Shoot in RAW\n✏️ Basic editing = huge impact\n\n#photography #iphonephotography #phototips #mobile #photographer",
            userResearchAnswer: "Distills five high-impact iPhone settings/techniques—portrait mode, no digital zoom, tap-to-focus, RAW capture, quick edits—so researchers can quickly upskill mobile teams.",
            commentsAnalysis: "Photography enthusiasts and beginners equally engaged. Many sharing their own before/after edits using these tips. Questions about recommended editing apps and specific iPhone model features. Some debate about RAW vs JPEG. Requests for more advanced tutorials and specific genre tips like landscape or portrait photography."
        ),

        ContentItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000008")!,
            thumbnailName: "brain.head.profile",
            title: "Productivity System That Works",
            createdDate: Date().addingTimeInterval(-86400 * 21),
            engagementMetrics: [
                MetricItem(count: "176k", iconName: "eye.fill"),
                MetricItem(count: "11k", iconName: "heart.fill"),
                MetricItem(count: "2.1k", iconName: "bubble.left.fill")
            ],
            viralStatus: "Trending",
            authorHandle: "@productivity_hacks",
            summary: "A detailed breakdown of a productivity system combining time-blocking, task management, and focus techniques. The creator shares their exact tools, daily schedule, and how they maintain work-life balance while managing multiple projects.",
            audioTranscription: "After trying every productivity system out there - GTD, Pomodoro, Bullet Journaling - I finally created a hybrid system that actually works for me. Here's the framework. I use Notion for task management, organized by projects and priority. Every Sunday, I do a weekly review where I plan out my major tasks. Each morning, I time-block my calendar - not just meetings, but dedicated focus blocks for deep work. I follow the two-minute rule: if something takes less than two minutes, do it immediately. For focus, I use 90-minute deep work sessions with 20-minute breaks. Phone on Do Not Disturb, email closed, just me and the task. I batch similar tasks together - all calls on Tuesday and Thursday afternoons, all admin work on Friday mornings. The key insight is that productivity isn't about doing more, it's about doing the right things at the right time. Protect your energy like you protect your time.",
            visualTranscription: "⚡️ My Productivity System (Finally One That Works)\n\nI tried everything. This is what stuck.\n\n🗓️ Weekly review Sundays\n⏱️ Time-blocking everything\n🎯 2-minute rule\n🔥 90-min deep work blocks\n📦 Task batching\n\nTools: Notion + Google Cal + Focus@Will\n\n#productivity #timemanagement #notion #worksmart #efficiency",
            userResearchAnswer: "Confirms that pairing weekly reviews with daily time-blocking, two-minute rule, and 90/20 focus cycles is an effective framework for multi-project workloads.",
            commentsAnalysis: "Highly engaged audience sharing their own productivity struggles and systems. Many questions about the specific Notion setup and template sharing. Discussion about adapting the system for different work types (creative vs analytical). Some people finding 90-minute blocks too long and asking about modifications. Requests for a follow-up on handling interruptions and unexpected tasks."
        )
    ]

    /// Returns a single sample item, useful for single item previews
    public static var sample: ContentItem {
        sampleData[0]
    }

    /// Returns a subset of rich sample data (first 4 items with full details)
    public static var richSamples: [ContentItem] {
        Array(sampleData.prefix(4))
    }
}
