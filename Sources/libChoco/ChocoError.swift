import Foundation

public enum ChocoError: Error {
  case errorReadingFile
  case noPlaylists
  case sameFilename
  case outputExist
  case noOutputFile(URL)
  case directoryInFileMode
  case inputNotExists
  case mkvmergeIdentification(Error)
  case ffmpegExtractAudio(Error)
  case validateFlacMD5(Error)
  case mkvmergeMux(Error)
  case parseBDMV(Error)
  case terminated
  case noHBCropInfo
}
