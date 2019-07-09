public struct MkvmergeMuxer: Executable {
    
    public static let executableName: String = "mkvmerge"
    
    public let input: [String]
    
    public let output: String
    
    let audioLanguages: Set<String>
    
    let subtitleLanguages: Set<String>
    
    let chapterPath: String?
    
    var extraArguments: [String]
    
    let cleanInputChapter: Bool
    
    public init(input: String, output: String) {
        self.input = [input]
        self.output = output
        self.audioLanguages = []
        self.subtitleLanguages = []
        self.chapterPath = nil
        self.extraArguments = []
        self.cleanInputChapter = false
    }
    
    public init(input: [String], output: String, audioLanguages: Set<String>,
                subtitleLanguages: Set<String>, chapterPath: String? = nil, extraArguments: [String] = [], cleanInputChapter: Bool = false) {
        self.input = input
        self.output = output
        self.audioLanguages = audioLanguages
        self.subtitleLanguages = subtitleLanguages
        if let path = chapterPath, !path.isEmpty {
            self.chapterPath = path
        } else {
            self.chapterPath = nil
        }
        self.extraArguments = extraArguments
        self.cleanInputChapter = cleanInputChapter
    }
    
    public var arguments: [String] {
        var arguments = ["-q", "--output", output, "--no-attachments"]
        if audioLanguages.count > 0 {
            arguments.append("-a")
            arguments.append(audioLanguages.joined(separator: ","))
        }
        if subtitleLanguages.count > 0 {
            arguments.append("-s")
            arguments.append(subtitleLanguages.joined(separator: ","))
        }
        
        if cleanInputChapter {
            arguments.append("--no-chapters")
        }
        arguments.append(input[0])
        if input.count > 1 {
            input[1...].forEach { (i) in
                if cleanInputChapter {
                    arguments.append("--no-chapters")
                }
                arguments.append("+")
                arguments.append(i)
            }
        }
        
        if chapterPath != nil {
            arguments.append(contentsOf: ["--chapters", chapterPath!])
        }
        
        arguments.append(contentsOf: extraArguments)
        
        return arguments
    }
    
}

public struct NewMkvmerge: Executable {
    public static let executableName: String = "mkvmerge"
    
    public let global: GlobalOption
    
    public struct GlobalOption {
        public var quiet: Bool
        public var webm: Bool
        public var title: String
        public var defaultLanguage: String?
        //    var split: Split?
        //    enum Split {
        //        case
        //    }
        public var trackOrder: [TrackOrder]?
        public struct TrackOrder {
            public let fid: Int
            public let tid: Int
            var argument: String {
                "\(fid):\(tid)"
            }
            public init(fid: Int, tid: Int) {
                self.fid = fid
                self.tid = tid
            }
        }
        
        public init(quiet: Bool, webm: Bool = false, title: String = "", defaultLanguage: String? = nil, trackOrder: [TrackOrder]? = nil) {
            self.quiet = quiet
            self.webm = webm
            self.title = title
            self.defaultLanguage = defaultLanguage
            self.trackOrder = trackOrder
        }
        
        var arguments: [String] {
            var r = [String]()
            if quiet {
                r.append("--quiet")
            }
            if webm {
                r.append("--webm")
            }
            r.append(contentsOf: ["--title", title])
            if let l = defaultLanguage {
                r.append(contentsOf: ["--default-language", l])
            }
            if let to = trackOrder, !to.isEmpty {
                r.append("--track-order")
                r.append(to.map{$0.argument}.joined(separator: ","))
            }
            return r
        }
    }
    
    public let output: String
    
    public let inputs: [Input]
    
    public struct Input {
        public enum InputOption {
            public enum TrackIndex {
                case none
                case enabledTIDs([Int])
                case enabledLANGs([String])
                case disabledTIDs([Int])
                case disabledLANGS([String])
                
                var argument: String {
                    switch self {
                    case .enabledTIDs(let tids):
                        return tids.map {String(describing: $0)}.joined(separator: ",")
                    case .disabledTIDs(let tids):
                        return "!" + tids.map {String(describing: $0)}.joined(separator: ",")
                    case .enabledLANGs(let langs):
                        return langs.joined(separator: ",")
                    case .disabledLANGS(let langs):
                        return "!" + langs.joined(separator: ",")
                    default:
                        fatalError()
                    }
                }
                
            }
            case audioTracks(TrackIndex)
            case videoTracks(TrackIndex)
            case subtitleTracks(TrackIndex)
            case buttonTracks(TrackIndex)
            case trackTags(TrackIndex)
            case attachments(TrackIndex)
            case noChapters
            case noGlobalTags
            case trackName(tid: Int, name: String)
            case language(tid: Int, language: String)
            
            var arguments: [String] {
                switch self {
                case .audioTracks(let i):
                    switch i {
                    case .none:
                        return ["--no-audio"]
                    default:
                        return ["--audio-tracks", i.argument]
                    }
                case .videoTracks(let i):
                    switch i {
                    case .none:
                        return ["--no-video"]
                    default:
                        return ["--video-tracks", i.argument]
                    }
                case .subtitleTracks(let i):
                    switch i {
                    case .none:
                        return ["--no-subtitles"]
                    default:
                        return ["--subtitle-tracks", i.argument]
                    }
                case .buttonTracks(let i):
                    switch i {
                    case .none:
                        return ["--no-buttons"]
                    default:
                        return ["--button-tracks", i.argument]
                    }
                case .trackTags(let i):
                    switch i {
                    case .none:
                        return ["--no-track-tags"]
                    default:
                        return ["--track-tags", i.argument]
                    }
                case .attachments(let i):
                    switch i {
                    case .none:
                        return ["--no-attachments"]
                    default:
                        return ["--attachments", i.argument]
                    }
                case .noChapters:
                    return ["--no-chapters"]
                case .noGlobalTags:
                    return ["--no-global-tags"]
                case .trackName(tid: let tid, name: let name):
                    return ["--track-name", "\(tid):\(name)"]
                case .language(tid: let tid, language: let lang):
                    return ["--language", "\(tid):\(lang)"]
                }
            }
        }
        public let file: String
        public let append: Bool
        public let options: [InputOption]
        
        public init(file: String, append: Bool = false, options: [InputOption] = []) {
            self.file = file
            self.append = append
            self.options = options
        }
        
        var arguments: [String] {
            var r = options.flatMap{$0.arguments}
            if append {
                r.append("+")
            }
            r.append(file)
            return r
        }
    }
    
    public var arguments: [String] {
        global.arguments + ["--output", output] + inputs.flatMap {$0.arguments}
    }
    
    public init(global: GlobalOption, output: String, inputs: [NewMkvmerge.Input]) {
        self.global = global
        self.output = output
        self.inputs = inputs
    }
}
