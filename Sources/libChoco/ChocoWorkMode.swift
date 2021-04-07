public enum ChocoWorkMode: String, CaseIterable, Codable {
  // mux and remux all mpls
  case remuxBDMV
  // only mux bdmv mpls
  case directBDMV
  // map all files to output dir's same dir structure
  case directory
  // input is *.mkv or something else
  case file
}
