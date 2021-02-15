//import Foundation
import ExecutableDescription

struct MP4Box: Executable {
  static let executableName: String = "MP4Box"

  var importings: [FileImporting]
  let tmp: String?

  let output: String

  var arguments: [String] {
    var result = [String]()

    tmp.map { result.append("-tmp"); result.append($0) }

    importings.forEach { fileImporting in
      // Syntax is add / cat filename[#FRAGMENT][:opt1...:optN=val]
      result.append("-add")
      result.append(fileImporting.argument)
    }

    result.append("-new")
    result.append(output)

    return result
  }

  struct FileImporting {
    enum TrackSelection {
      case video
      case audio
      case auxv
      case pict
      case trackID(Int)
      case pID(Int)
      case progID(Int)
      case program(String)

      var fragment: String {
        switch self {
        case .audio: return "audio"
        case .auxv: return "auxv"
        case .pID(let v): return "pid=\(v)"
        case .pict: return "pict"
        case .progID(let v): return "prog_id=\(v)"
        case .program(let v): return "program=\(v)"
        case .trackID(let v): return "trackID=\(v)"
        case .video: return "video"
        }
      }
    }

    let filename: String
    let trackSelection: TrackSelection?
    /// set track handler name
    let name: String?
    let fps: String?
    /// add the track as part of the G alternate group. If G is 0, the first available GroupID will be picked
    let group: Int?
    /// set visual track pixel aspect ratio
    let par: String?
    /// set imported media language code
    let language: String?

    let isChapter: Bool

    var argument: String {
      var result = filename

      if let fragment = trackSelection?.fragment {
        result.append("#")
        result.append(fragment)
      }

      func addOption(value: String?, key: String) {
        guard let v = value else {
          return
        }
        result.append(":")
        result.append(key)
        result.append("=")
        result.append(v)
      }

      addOption(value: name, key: "name")
      addOption(value: fps, key: "fps")
      addOption(value: group?.description, key: "group")
      addOption(value: language, key: "lang")
      if isChapter {
        result.append(":chap")
      }
      addOption(value: par, key: "par")

      return result
    }
    /*
     dur (int):                     X import only the specified duration from the media. Value can be:
     * positive float: specifies duration in seconds
     * fraction: specifies duration as NUM/DEN fraction
     * negative integer: specifies duration in number of coded frames
     delay (int):                   set imported media initial delay in ms
     -par  tkID=PAR (string):       set visual track pixel aspect ratio. PAR is:
     * N:D: set PAR to N:D in track, do not modify the bitstream
     * wN:D: set PAR to N:D in track and try to modify the bitstream
     * none: remove PAR info from track, do not modify the bitstream
     * auto: retrieve PAR info from bitstream and set it in track
     * force: force 1:1 PAR in track, do not modify the bitstream
     par (string):                  set visual pixel aspect ratio (see -par )
     clap (string):                 set visual clean aperture (see -clap )
     mx (string):                   set track matrix (see -mx )
     ext (string):                  override file extension when importing
     hdlr (string):                 set track handler type to the given code point (4CC)
     disable:                       disable imported track(s)

     rap:                           D import only RAP samples
     refs:                          D import only reference pictures
     trailing:                      keep trailing 0-bytes in AVC/HEVC samples
     agg (int):                     X same as agg
     dref:                          X same as dref
     keep_refs:                     keep track reference when importing a single track
     nodrop:                        same as nodrop
     packed:                        X same as packed
     sbr:                           same as sbr
     sbrx:                          same as sbrx
     ovsbr:                         same as ovsbr
     ps:                            same as ps
     psx:                           same as psx
     asemode (string):              X set the mode to create the AudioSampleEntry. Value can be:
     * v0-bs: use MPEG AudioSampleEntry v0 and the channel count from the bitstream (even if greater than 2) - default
     * v0-2: use MPEG AudioSampleEntry v0 and the channel count is forced to 2
     * v1: use MPEG AudioSampleEntry v1 and the channel count from the bitstream
     * v1-qt: use QuickTime Sound Sample Description Version 1 and the channel count from the bitstream (even if greater than 2). This will also trigger using alis data references instead of url, even for non-audio tracks
     audio_roll (int):              add a roll sample group with roll_distance N
     mpeg4:                         X same as mpeg4 option
     nosei:                         discard all SEI messages during import
     svc:                           import SVC/LHVC with explicit signaling (no AVC base compatibility)
     nosvc:                         discard SVC/LHVC data when importing
     svcmode (string):              D set SVC/LHVC import mode. Value can be:
     * split: each layer is in its own track
     * merge: all layers are merged in a single track
     * splitbase: all layers are merged in a track, and the AVC base in another
     * splitnox: each layer is in its own track, and no extractors are written
     * splitnoxib: each layer is in its own track, no extractors are written, using inband param set signaling
     temporal (string):             D set HEVC/LHVC temporal sublayer import mode. Value can be:
     * split: each sublayer is in its own track
     * splitbase: all sublayers are merged in a track, and the HEVC base in another
     * splitnox: each layer is in its own track, and no extractors are written
     subsamples:                    add SubSample information for AVC+SVC
     deps:                          import sample dependency information for AVC and HEVC
     ccst:                          add default HEIF ccst box to visual sample entry
     forcesync:                     force non IDR samples with I slices to be marked as sync points (AVC GDR)

     Warning: RESULTING FILE IS NOT COMPLIANT WITH THE SPEC but will fix seeking in most players

     xps_inband:                    X set xPS inband for AVC/H264 and HEVC (for reverse operation, re-import from raw media)
     xps_inbandx:                   X same as xps_inband and also keep first xPS in sample desciption
     au_delim:                      keep AU delimiter NAL units in the imported file
     max_lid (int):                 set HEVC max layer ID to be imported to N (by default imports all layers)
     max_tid (int):                 set HEVC max temporal ID to be imported to N (by default imports all temporal sublayers)
     tiles:                         add HEVC tiles signaling and NALU maps without splitting the tiles into different tile tracks
     split_tiles:                   D split HEVC tiles into different tile tracks, one tile (or all tiles of one slice) per track
     negctts:                       use negative CTS-DTS offsets (ISO4 brand)
     chap:                          specify the track is a chapter track
     chapter (string):              add a single chapter (old nero format) with given name lasting the entire file
     chapfile (string):             add a chapter file (old nero format)
     layout (string):               specify the track layout as WxHxXxY
     * if W (resp H) = 0: the max width (resp height) of the tracks in the file are used
     * if Y=-1: the layout is moved to the bottom of the track area
     * X and Y can be omitted: :layout=WxH
     rescale (int):                 force media timescale to TS !! changes the media duration
     timescale (int):               set imported media timescale to TS
     moovts (int):                  set movie timescale to TS. A negative value picks the media timescale of the first track imported
     noedit:                        X do not set edit list when importing B-frames video tracks
     rvc (string):                  set RVC configuration for the media
     fmt (string):                  override format detection with given format (cf BT/XMTA doc)
     profile (int):                 override AVC profile
     level (int):                   override AVC level
     novpsext:                      remove VPS extensions from HEVC VPS
     keepav1t:                      keep AV1 temporal delimiter OBU in samples, might help if source file had losses
     font (string):                 specify font name for text import (default Serif)
     size (int):                    specify font size for text import (default 18)
     text_layout (string):          specify the track text layout as WxHxXxY
     * if W (resp H) = 0: the max width (resp height) of the tracks in the file are used
     * if Y=-1: the layout is moved to the bottom of the track area
     * X and Y can be omitted: :layout=WxH
     swf-global:                    all SWF defines are placed in first scene replace rather than when needed
     swf-no-ctrl:                   use a single stream for movie control and dictionary (this will disable ActionScript)
     swf-no-text:                   remove all SWF text
     swf-no-font:                   remove all embedded SWF Fonts (local playback host fonts used)
     swf-no-line:                   remove all lines from SWF shapes
     swf-no-grad:                   remove all gradients from SWF shapes
     swf-quad:                      use quadratic bezier curves instead of cubic ones
     swf-xlp:                       support for lines transparency and scalability
     swf-ic2d:                      use indexed curve 2D hardcoded proto
     swf-same-app:                  appearance nodes are reused
     swf-flatten (number):          complementary angle below which 2 lines are merged, 0 means no flattening
     kind (string):                 set kind for the track as schemeURI=value
     txtflags (int):                set display flags (hexa number) of text track. Use txtflags+=FLAGS to add flags and txtflags-=FLAGS to remove flags
     rate (int):                    force average rate and max rate to VAL (in bps) in btrt box. If 0, removes btrt box
     stz2:                          use compact size table (for low-bitrates)
     bitdepth (int):                set bit depth to VAL for imported video content (default is 24)
     colr (string):                 set color profile for imported video content (see ISO/IEC 23001-8). Value is formatted as:
     * nclc,p,t,m: with p colour primary, t transfer characteristics and m matrix coef
     * nclx,p,t,m,r: same as nclx with r full range flag
     * prof,path: with path indicating the file containing the ICC color profile
     * rICC,path: with path indicating the file containing the restricted ICC color profile
     dv-profile (int):              set the Dolby Vision profile
     tc (string):                   inject a single QT timecode. Value is formated as:
     * [d]FPS[/FPS_den],h,m,s,f[,framespertick]: optional drop flag, framerate (integer or fractional), hours, minutes, seconds and frame number
     * : d is an optional flag used to indicate that the counter is in drop-frame format
     * : the framespertick is optional and defaults to round(framerate); it indicates the number of frames per counter tick
     lastsampdur (string):          set duration of the last sample. Value is formated as:
     * no value: use the previous sample duration
     * integer: indicate the duration in milliseconds
     * N/D: indicate the duration as fractional second
     fstat:                         print filter session stats after import
     fgraph:                        print filter session graph after import
     sopt:[OPTS]:                   set OPTS as additional arguments to source filter. OPTS can be any usual filter argument, see filter doc `gpac -h doc`
     dopt:[OPTS]:                   X set OPTS as additional arguments to destination filter. OPTS can be any usual filter argument, see filter doc `gpac -h doc`
     @@f1[:args][@@fN:args]:        set a filter chain to insert before the muxer. Each filter in the chain is formatted as a regular filter, see filter doc `gpac -h doc`. If several filters are set, they will be chained in the given order. The last filter shall not have any Filter ID specified
     */
  }

}
