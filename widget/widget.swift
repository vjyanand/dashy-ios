import WidgetKit
import SwiftUI
import os.log

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, configuration: configuration)
            entries.append(entry)
        }
        return Timeline(entries: entries, policy: .atEnd)
    }

//    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
}

struct widgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.levelOfDetail) var levelOfDetail: LevelOfDetail

    var body: some View {
        switch levelOfDetail {
        case .simplified:
            VStack {
                Text(entry.date, style: .time)

                Text(entry.configuration.favoriteEmoji)
            }
        default:
            VStack {
                Text("Time1:")
                Text(entry.date, style: .time)

                Text("Favorite Emoji1:")
                Text(entry.configuration.favoriteEmoji)
            }
        }
    }
}

struct widget: Widget {
    let kind: String = "widget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            widgetEntryView(entry: entry)
                .containerBackground(.yellow, for: .widget)
        }
        .configurationDisplayName("config")
        .supportedFamilies([.systemSmall, .systemMedium])
        .supportedMountingStyles([.elevated])
        .pushHandler(ControlWidgetPushHandler.self)
    }
}
// pushTokenDidChange is not called consistently
// Expected to be called for every widget creation and change of WidgetConfigurationIntent
// token generated is like "80429f4faa56125c0c7fadafd42d998c97717e2d769274591483beed6701d56cd176ea000f58d9241c10d3ae2519848686a5d580586eafc73b8c19274331983f6581d05064fde8e415c04b6f39efadf3" which online token validator says as invalid

struct ControlWidgetPushHandler: WidgetPushHandler {
    func pushTokenDidChange(_ pushInfo: WidgetPushInfo, widgets: [WidgetInfo]) {
        var widgetArray: [[String: Any]] = []
        for widget in widgets {
            var widgetDetail: [String:Any] = [:]
            widgetDetail["kind"] = widget.kind
            widgetDetail["family"] = widget.family.description
            guard let confItent = widget.widgetConfigurationIntent(of: ConfigurationAppIntent.self) else { return }
            widgetDetail["dashyId"] = confItent.favoriteEmoji
            widgetArray.append(widgetDetail)
        }
        var payload: [String:Any] = [:]
        let token = pushInfo.token.map { String(format: "%02.2hhx", $0) }.joined()
        payload["token"] = token
        payload["widgets"] = widgetArray
        
        print("DASHEE token: \(token)")
        
        guard let url = URL(string: "https://dashy-api.fly.dev/ios/widget/apns/register") else {
            print("Invalid URL")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
            request.httpBody = jsonData
        } catch {
            print("DASHEE Error serializing payload to JSON: \(error)")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("DASHEE Error sending POST request: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("DASHEE Invalid response from server")
                return
            }
            
            if (200...299).contains(httpResponse.statusCode) {
                print("DASHEE Successfully sent payload to backend")
            } else {
                print("DASHEE Server responded with status code: \(httpResponse.statusCode)")
            }
            
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("DASHEE Server response: \(responseString)")
            }
    
        }
        task.resume()
        
    }
}

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "🤩"
        return intent
    }
}
