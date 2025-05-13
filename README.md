# Remuxer

A description of this package.

# Requirements
FFmpeg(--enable-shared --enable-avresample)
flac
mkvtoolnix


# Features
Automatic remux all bd playlist
Convert gross audio format to flac
Remove truehd embed ac3 track
Remove duplicate audio tracks(use flac md5)
Language filter
Split mpls according to m2ts while keeping the chapter


filter crop order

no vs:
filter(or crop-filter if provided) -> crop
add crop to filter end

vs:
filter(or crop-filter if provided) -> crop
add crop to filter end
