public enum BDRemuxerMode: String, CaseIterable, Codable {
    // direct mux all mpls
    case movie
    // split all mpls
    case episodes
    // print mpls list
//    case dumpBDMV
    // input is *.mkv or something else
    case file
}
