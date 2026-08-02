//===----------------------------------------------------------------------===//
// Copyright © 2025-2026 Apple Inc. and the Containerization project authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//===----------------------------------------------------------------------===//

//  swiftlint: disable force_try shorthand_operator static_over_final_class

import Foundation
import SystemPackage
import Testing

@testable import ContainerizationEXT4

struct Ext4FormatTests: ~Copyable {
    let fsPath = FilePath(
        FileManager.default.uniqueTemporaryDirectory()
            .appendingPathComponent("ext4.img.delme.format", isDirectory: false))

    // This test creates a file named "ext4.img.delme"
    // Since there are no tools yet in osx/swift to test the created filesystem,
    // the tests below perform the same checks as the following manual commands
    //
    // From project root
    // $> backpack run -it -v SwiftExt4/Tests/SwiftExt4Tests/:/test -w test ubuntu:latest
    // $> ls -lrth ext4.img.delme # should be only 44K
    // $> e2fsck ext4.img.delme # should return 0
    // $> dumpe2fs ext4.img.delme # should print info and return 0
    // $> debugfs ext4.img.delme # should open the fs
    //   debugfs 1.46.5 (30-Dec-2021)
    //   debugfs:  ls
    //   2  (12) .    2  (12) ..    15  (12) x    11  (20) lost+found    12  (12) ase
    //   16  (12) y    0  (4016)
    //
    //  # check directory
    //
    //   debugfs:  stat /test
    //   Inode: 12   Type: directory    Mode:  01274   Flags: 0xc0000
    //   Generation: 0    Version: 0x00000000:00000000
    //   User:     0   Group:     0   Size: 4096
    //   File ACL: 0
    //   Links: 3   Blockcount: 1
    //   Fragment:  Address: 0    Number: 0    Size: 0
    //    ctime: 0x6614b59f:8cdf6a34 -- Tue Apr  9 03:27:27 2024
    //    atime: 0x6614b59f:8cdf6a34 -- Tue Apr  9 03:27:27 2024
    //    mtime: 0x6614b59f:8cdf6a34 -- Tue Apr  9 03:27:27 2024
    //    crtime: 0x6614b59f:8cdf6a34 -- Tue Apr  9 03:27:27 2024
    //   Size of extra inode fields: 24
    //   EXTENTS:
    //    (0):5
    //
    //  # check regular file
    //
    //   debugfs:  stat /test/foo/bar/x
    //   Inode: 15   Type: regular    Mode:  01363   Flags: 0xc0000
    //   Generation: 0    Version: 0x00000000:00000000
    //   User:     0   Group:     0   Size: 4
    //   File ACL: 0
    //   Links: 2   Blockcount: 1
    //   Fragment:  Address: 0    Number: 0    Size: 0
    //    ctime: 0x6614b59f:8ce91ef8 -- Tue Apr  9 03:27:27 2024
    //    atime: 0x6614b59f:8ce91ef8 -- Tue Apr  9 03:27:27 2024
    //    mtime: 0x6614b59f:8ce91ef8 -- Tue Apr  9 03:27:27 2024
    //    crtime: 0x6614b59f:8ce91ef8 -- Tue Apr  9 03:27:27 2024
    //   Size of extra inode fields: 24
    //   EXTENTS:
    //    (0):2
    //
    //   # check symlink
    //
    //   debugfs:  stat /y
    //   Inode: 16   Type: symlink    Mode:  01675   Flags: 0x0
    //   Generation: 0    Version: 0x00000000:00000000
    //   User:     0   Group:     0   Size: 19
    //   File ACL: 0
    //   Links: 1   Blockcount: 0
    //   Fragment:  Address: 0    Number: 0    Size: 0
    //    ctime: 0x6614b59f:8cf052fc -- Tue Apr  9 03:27:27 2024
    //    atime: 0x6614b59f:8cf052fc -- Tue Apr  9 03:27:27 2024
    //    mtime: 0x6614b59f:8cf052fc -- Tue Apr  9 03:27:27 2024
    //    crtime: 0x6614b59f:8cf052fc -- Tue Apr  9 03:27:27 2024
    //   Size of extra inode fields: 24
    //   Fast link dest: "test/foo"
    //
    //   # check hard link
    //
    //   debugfs:  stat x
    //   Inode: 15   Type: regular    Mode:  01363   Flags: 0xc0000
    //   Generation: 0    Version: 0x00000000:00000000
    //   User:     0   Group:     0   Size: 4
    //   File ACL: 0
    //   Links: 2   Blockcount: 1
    //   Fragment:  Address: 0    Number: 0    Size: 0
    //    ctime: 0x6614b59f:8ce91ef8 -- Tue Apr  9 03:27:27 2024
    //    atime: 0x6614b59f:8ce91ef8 -- Tue Apr  9 03:27:27 2024
    //    mtime: 0x6614b59f:8ce91ef8 -- Tue Apr  9 03:27:27 2024
    //    crtime: 0x6614b59f:8ce91ef8 -- Tue Apr  9 03:27:27 2024
    //   Size of extra inode fields: 24
    //   EXTENTS:
    //    (0):2
    //
    // Mount and check
    //
    // $> mkdir -p mntpnt
    // $> mount -t ext4 ext4.img.delme mntpnt
    // $> # explore file tree
    init() throws {
        let formatter = try EXT4.Formatter(fsPath, minDiskSize: 32.kib())
        try formatter.create(path: FilePath("/test"), mode: EXT4.Inode.Mode(.S_IFDIR, 0o700))
        try formatter.create(path: FilePath("/test/foo"), mode: EXT4.Inode.Mode(.S_IFDIR, 0o700))
        try formatter.create(path: FilePath("/test/foo/bar"), mode: EXT4.Inode.Mode(.S_IFDIR, 0o700))
        let inputStream = InputStream(data: "test".data(using: .utf8)!)
        inputStream.open()
        try formatter.create(
            path: FilePath("/test/foo/bar/x"), mode: EXT4.Inode.Mode(.S_IFREG, 0o755),
            buf: inputStream)  // create a regular file
        inputStream.close()
        try formatter.link(link: FilePath("/x"), target: FilePath("/test/foo/bar/x"))
        try formatter.create(
            path: FilePath("/y"), link: FilePath("test/foo"), mode: EXT4.Inode.Mode(.S_IFLNK, 0o700))  // create a symlink

        try formatter.close()
    }

    deinit {
        try? FileManager.default.removeItem(at: fsPath.url)
    }

    /// This test checks that the size of the FS at fsPath is the minimum possible
    /// for its data + metadata. It should be 44 kib or 11 blocks, expanded to accommodate
    /// data requiring > 32KiB of space
    @Test func fileSize() throws {
        let f = try FileHandle(forReadingFrom: fsPath.url)
        let size = try f.seekToEnd()
        #expect(size == 128.mib())
    }

    /// This test checks that the superblock was created correctly
    @Test func superblock() throws {
        let f = try EXT4.EXT4Reader(blockDevice: fsPath)
        #expect(f.superBlock.blocksCountLow == 32768)
        #expect(f.superBlock.freeBlocksCountLow < f.superBlock.blocksCountLow)
        #expect(f.superBlock.freeBlocksCountLow > 0)
    }

    /// This test checks that the group descriptor has been set correctly
    @Test func groupDescriptors() throws {
        let f = try EXT4.EXT4Reader(blockDevice: fsPath)
        let gd = try f.getGroupDescriptor(0)
        #expect(gd.inodeTableLow < gd.blockBitmapLow)
        #expect(gd.blockBitmapLow < gd.inodeBitmapLow)
        #expect(gd.freeBlocksCountLow <= f.superBlock.blocksCountLow)
        #expect(gd.freeInodesCountLow <= f.superBlock.inodesPerGroup)
        #expect(gd.usedDirsCountLow == 5)
    }

    /// This test checks that the block bitmap has been set correctly
    @Test func blockBitmap() throws {
        let ext4 = try EXT4.EXT4Reader(blockDevice: fsPath)
        let gd = try ext4.getGroupDescriptor(1)
        let blockBitmapOffset = gd.blockBitmapLow
        let f = try #require(FileHandle(forReadingFrom: fsPath))
        try f.seek(toOffset: ext4.blockSize * blockBitmapOffset)
        let bitmapSize = ext4.superBlock.blocksPerGroup / 8
        #expect(bitmapSize == 4096)
        let _ = try f.read(
            upToCount: Int(ext4.superBlock.blocksCountLow - ext4.superBlock.freeBlocksCountLow - 1) / 8 + 1)
    }

    /// This test checks that the inode bitmap has been set correctly
    @Test func inodeBitmap() throws {
        let ext4 = try EXT4.EXT4Reader(blockDevice: fsPath)
        let gd = try ext4.getGroupDescriptor(1)
        let inodeBitmapOffset = gd.inodeBitmapLow
        let f = try #require(FileHandle(forReadingFrom: fsPath))
        try f.seek(toOffset: ext4.blockSize * inodeBitmapOffset)
        let bitmapSize = ext4.superBlock.inodesPerGroup / 8
        #expect(bitmapSize == ext4.superBlock.inodesPerGroup / 8)
    }

    /// This test checks that the inode table has been set correctly
    @Test func inodeTable() throws {
        let ext4 = try EXT4.EXT4Reader(blockDevice: fsPath)
        let gd = try ext4.getGroupDescriptor(0)
        let inodeTableOffset = gd.inodeTableLow
        let f = try #require(FileHandle(forReadingFrom: fsPath))
        try f.seek(toOffset: ext4.blockSize * inodeTableOffset)
        let inodeTableSize = ext4.superBlock.inodesPerGroup * UInt32(ext4.superBlock.inodeSize)
        #expect(inodeTableSize == ext4.superBlock.inodesPerGroup * UInt32(ext4.superBlock.inodeSize))
        let inodeTableData = try #require(try f.read(upToCount: Int(inodeTableSize)))
        let inodeAt: (Int) -> EXT4.Inode = { inodeNum in
            var inodeBytes: [UInt8] = .init(repeating: 0, count: Int(ext4.superBlock.inodeSize))
            let inodeStart = Int(ext4.superBlock.inodeSize) * (inodeNum - 1)
            var j: Int = 0
            for i in inodeStart..<inodeStart + Int(ext4.superBlock.inodeSize) {
                inodeBytes[j] = inodeTableData[i]
                j = j + 1
            }
            return inodeBytes.withUnsafeBytes { ptr in
                ptr.loadLittleEndian(as: EXT4.Inode.self)
            }
        }
        let root = inodeAt(2)
        #expect(root.mode.isDir())
        #expect(root.linksCount == 4)

        let regFile = inodeAt(15)
        #expect(regFile.mode.isReg())
        #expect(regFile.sizeLow == 4)
    }

    @Test func largeEmptyPackedMetadataImagesRemainConsistent() throws {
        struct EmptyImageCase {
            let requested: UInt64
            let ceilingMiB: UInt64?
        }
        let testCases: [EmptyImageCase] = [
            // .init(requested: 32.kib(), ceilingMiB: nil), // Size < 128. The EXT4 formatter will round up to 128MiB.
            // .init(requested: 64.mib(), ceilingMiB: nil), // Size < 128. The EXT4 formatter will round up to 128MiB.
            .init(requested: 128.mib(), ceilingMiB: nil),
            .init(requested: 128.mib() + 4.kib(), ceilingMiB: nil),
            .init(requested: 130.mib() + 8.kib(), ceilingMiB: nil),
            .init(requested: 160.mib(), ceilingMiB: nil),
            .init(requested: 160.mib() + 4.kib(), ceilingMiB: nil),
            .init(requested: 256.mib(), ceilingMiB: nil),
            .init(requested: 1.gib(), ceilingMiB: nil),
            .init(requested: 4.gib(), ceilingMiB: 32),
            .init(requested: 63 * 128.mib(), ceilingMiB: 32),
            .init(requested: 63 * 128.mib() + 4.kib(), ceilingMiB: 32),
            .init(requested: 8.gib(), ceilingMiB: 32),
            .init(requested: 16.gib(), ceilingMiB: 32),
        ]

        for testCase in testCases {
            let requested = testCase.requested
            // let ceilingMiB = testCase.ceilingMiB ?? 32
            let fsPath = FilePath(
                FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
            )
            defer { try? FileManager.default.removeItem(at: fsPath.url) }

            let formatter = try EXT4.Formatter(fsPath, minDiskSize: requested)
            try formatter.close()

            let file = try FileHandle(forReadingFrom: fsPath.url)
            let fileSize = try file.seekToEnd()

            let ext4 = try EXT4.EXT4Reader(blockDevice: fsPath)
            let sb = ext4.superBlock
            let blocksCount = UInt64(sb.blocksCountLow) | (UInt64(sb.blocksCountHigh) << 32)
            let blockSize: UInt64 = UInt64(sb.blockSize)

            #expect(fileSize == requested)
            #expect(fileSize == blocksCount * blockSize)

            if let ceilingMiB = testCase.ceilingMiB {
                var fileStat = stat()
                let result = stat(fsPath.string, &fileStat)
                #expect(result == 0)
                guard result == 0 else {
                    continue
                }

                let physicalBytes = UInt64(fileStat.st_blocks) * 512
                let ceilingBytes = ceilingMiB * 1024 * 1024

                #expect(
                    physicalBytes <= ceilingBytes,
                    "physicalBytes <= ceilingBytes = false; physicalBytes = \(physicalBytes); ceilingBytes = \(ceilingBytes)"
                )
            }

            let gd1 = try ext4.getGroupDescriptor(1)
            #expect(UInt64(gd1.inodeTableLow) < blocksCount)
            #expect(UInt64(gd1.blockBitmapLow) < blocksCount)
            #expect(UInt64(gd1.inodeBitmapLow) < blocksCount)
            #expect(UInt64(gd1.inodeTableLow) < UInt64(sb.blocksPerGroup))
        }
    }

    @Test func largeContentPackedMetadataImagesRemainConsistent() throws {
        let cases: [(requested: UInt64, contentBytes: UInt64)] = [
            (requested: 128.mib(), contentBytes: 50.mib()),
            (requested: 160.mib(), contentBytes: 10.mib()),
            (requested: 160.mib(), contentBytes: 120.mib()),
            (requested: 160.mib(), contentBytes: 124.mib()),
            (requested: 160.mib(), contentBytes: 126.mib()),
            (requested: 300.mib(), contentBytes: 260.mib()),
            (requested: 63 * 128.mib(), contentBytes: 500.mib()),
            (requested: 256.mib(), contentBytes: 130.mib()),
            (requested: 1.gib(), contentBytes: 200.mib()),
            (requested: 300.mib(), contentBytes: 260.mib()),
            (requested: 4.gib(), contentBytes: 260.mib()),
            (requested: 8.gib(), contentBytes: 300.mib()),
            (requested: 16.gib(), contentBytes: 1000.mib()),
        ]

        for (requested, contentBytes) in cases {
            let fsPath = FilePath(
                FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
            )
            defer { try? FileManager.default.removeItem(at: fsPath.url) }

            let formatter = try EXT4.Formatter(fsPath, minDiskSize: requested)
            let payload = Data(repeating: 0x41, count: Int(contentBytes))
            let inputStream = InputStream(data: payload)
            inputStream.open()
            try formatter.create(path: FilePath("/content"), mode: EXT4.Inode.Mode(.S_IFREG, 0o755), buf: inputStream)
            inputStream.close()
            try formatter.close()

            let file = try FileHandle(forReadingFrom: fsPath.url)
            let fileSize = try file.seekToEnd()
            #expect(fileSize == requested)

            let ext4 = try EXT4.EXT4Reader(blockDevice: fsPath)
            let sb = ext4.superBlock
            let blocksCount = UInt64(sb.blocksCountLow) | (UInt64(sb.blocksCountHigh) << 32)
            let gd1 = try ext4.getGroupDescriptor(1)
            #expect(UInt64(gd1.inodeTableLow) < blocksCount)
            #expect(UInt64(gd1.blockBitmapLow) < blocksCount)
            #expect(UInt64(gd1.inodeBitmapLow) < blocksCount)
        }
    }
}

@Suite(.serialized)
struct NegativeTimestampRoundtripTests {
    private let fsPath = FilePath(
        FileManager.default.temporaryDirectory
            .appendingPathComponent("ext4-pre1970-roundtrip.img", isDirectory: false))
    private let apollo11MoonLanding: Date = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.date(from: "1969-07-20T20:17:39.9Z")!
    }()

    @Test func encodeNegativeTimestamp() throws {
        let formatter = try EXT4.Formatter(fsPath, minDiskSize: 32.kib())
        defer { try? formatter.close() }
        let ts = FileTimestamps(access: apollo11MoonLanding, modification: apollo11MoonLanding, creation: apollo11MoonLanding)
        try formatter.create(path: FilePath("/file"), mode: EXT4.Inode.Mode(.S_IFREG, 0o755), ts: ts, buf: nil)
    }

    @Test func decodeNegativeTimestamp() throws {
        let reader = try EXT4.EXT4Reader(blockDevice: fsPath)
        let (_, inode) = try reader.stat(FilePath("/file"))
        let mtime = Date(fsTimestamp: UInt64(inode.mtime) | (UInt64(inode.mtimeExtra) << 32))
        let atime = Date(fsTimestamp: UInt64(inode.atime) | (UInt64(inode.atimeExtra) << 32))
        let crtime = Date(fsTimestamp: UInt64(inode.crtime) | (UInt64(inode.crtimeExtra) << 32))
        #expect(mtime == apollo11MoonLanding)
        #expect(atime == apollo11MoonLanding)
        #expect(crtime == apollo11MoonLanding)
    }
}

struct Ext4FormatEmptyRangeTests {
    @Test func closeEmptyFilesystem() throws {
        let fsPath = FilePath(
            FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString, isDirectory: false))
        defer { try? FileManager.default.removeItem(at: fsPath.url) }
        let formatter = try EXT4.Formatter(fsPath, minDiskSize: 32.kib())
        try formatter.close()
    }
}
