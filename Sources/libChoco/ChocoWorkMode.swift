public enum ChocoWorkMode: String, CaseIterable, Codable {
  // direct mux all mpls
  case movie
  // split all mpls
  case episodes
  // map all files to output dir's same dir structure
  case directory
  // input is *.mkv or something else
  case file
}
