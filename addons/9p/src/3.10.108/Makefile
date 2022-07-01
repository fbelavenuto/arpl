obj-m := 9p.o

9p-objs := \
	vfs_super.o \
	vfs_inode.o \
	vfs_inode_dotl.o \
	vfs_addr.o \
	vfs_file.o \
	vfs_dir.o \
	vfs_dentry.o \
	v9fs.o \
	fid.o  \
	xattr.o \
	xattr_user.o

9p-y += cache.o
9p-n += acl.o

obj-m := 9pnet.o
obj-m += 9pnet_virtio.o
obj-n += 9pnet_rdma.o

9pnet-objs := \
        mod.o \
        client.o \
        error.o \
        util.o \
        protocol.o \
        trans_fd.o \
        trans_common.o \

9pnet_virtio-objs := \
        trans_virtio.o

9pnet_rdma-objs := \
        trans_rdma.o
