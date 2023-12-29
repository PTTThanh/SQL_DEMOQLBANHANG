-- Lấy danh sách nhân viên cùng tiền bán hàng trong năm X
WITH cte_ThongKeTheoNhanVien(MaNV, HoTen, Nam, DoanhSo)
AS(
	SELECT nv.MaNV, nv.HoTen, YEAR(NgayDat), SUM(SoLuong * DonGia * (1 - GiamGia))
	FROM NhanVien nv JOIN HoaDon hd ON hd.MaNV = nv.MaNV
		             JOIN ChiTietHD cthd ON cthd.MaHD=hd.MaHD
	GROUP BY nv.MaNV, nv.HoTen, YEAR(NgayDat)
)

SELECT * FROM cte_ThongKeTheoNhanVien
WHERE Nam = 1996
--Lấy số lượng đơn hàng trung bình của nhân viên trong năm X
WITH cte_DonHangTrungBinh 
AS(
		SELECT hd.MaNV, YEAR(NgayDat) as Nam, COUNT(hd.MaHD) as SoLuongDon
		FROM HoaDon hd
		GROUP BY hd.MaNV, YEAR(NgayDat)
)
SELECT AVG(SoLuongDon) as LuongDonTrungBinh
FROM cte_DonHangTrungBinh
WHERE Nam = 1996
--Thêm loại hàng hóa
CREATE PROC spThemHangHoa 
    @MaLoai int output,
	@TenLoai nvarchar(50),
	@MoTa nvarchar(max),
	@Hinh nvarchar(50)
AS
BEGIN
	Insert into Loai(TenLoai, Hinh, MoTa) values (@TenLoai, @Hinh, @MoTa)
	Set @MaLoai = @@IDENTITY
END
-- Demo thêm loại hàng hóa
Declare @Ma int
Exec spThemHangHoa  @Ma OUT, N'Văn phòng phẩm',N'Văn phòng phẩm',N'N/A'
Print concat(N'Ma loai dc them', @Ma)

-- Cập nhật loại hàng hóa
CREATE PROC spCapNhatHangHoa
	@MaLoai int,
	@TenLoai nvarchar(50),
	@MoTa nvarchar(max)
AS 
BEGIN
	UPDATE Loai
	SET TenLoai = @TenLoai , MoTa =@MoTa
	WHERE MaLoai = @MaLoai
END
-- Demo
Exec spCapNhatHangHoa 1001, N'Bàn làm việc',N'Bàn làm việc cho nhân viên'
--Kiểm tra sao khi xóa
SELECT * FROM Loai
-- Xóa loại hàng hóa
CREATE PROC spXoaLoai
	@MaLoai int
AS
BEGIN
	DELETE FROM Loai WHERE MaLoai = @MaLoai
END
---Demo
Exec spXoaLoai 2011
-- Kiểm tra sao khi xóa
SELECT * FROM Loai
--Liệt kê danh sách khách hàng (HoTen, DienThoai) có đơn đặt hàng với tổng tiền trên X
Create proc spLietKeKhachHang
	@SoTien float
As
Begin
	Select kh.HoTen, kh.DienThoai, Sum(cthd.SoLuong *cthd.DonGia) as TongTien
	From KhachHang kh join HoaDon hd on hd.MaKH = kh.MaKH join ChiTietHD cthd on cthd.MaHD = hd.MaHD
	Group by kh.HoTen, kh.DienThoai
	Having sum(cthd.SoLuong * cthd.DonGia) > @SoTien
End
-- Demo
Exec spLietKeKhachHang 3000
--Khi người dùng đặt hàng hãy tự động cập nhật số lượng tồn trong bảng kho hàng.
CREATE TRIGGER trg_CapNhatSoLuongTon
	ON ChiTietHD
	AFTER INSERT
AS BEGIN
-- Lấy thông tin vừa insert
	DECLARE @MaHH int
	DECLARE @SoLuongMua int
	SELECT @MaHH = MaHH, @SoLuongMua = SoLuong
	FROM inserted
-- Cập nhật giảm số lượng tồn hàng hóa
	UPDATE HangHoa
	SET SoLuong = SoLuong - @SoLuongMua
	WHERE MaHH = @MaHH
END
-- Demo thử thêm 1 CTHD vào hóa đơn
SELECT * FROM ChiTietHD WHERE MaHD = 10250
SELECT * FROM HangHoa WHERE MaHH =1001
INSERT INTO ChiTietHD(MaHD,MaHH, SoLuong, DonGia, GiamGia) VALUES (10250, 1001, 10, 190,0)

--Tự động cập nhật tổng tiền của hóa đơn khi thay đổi chi tiết hóa đơn
CREATE TRIGGER trg_CapNhatThanhTien
	ON ChitietHD
	AFTER INSERT, UPDATE, DELETE
AS BEGIN
	DECLARE @MaHD int
	DECLARE @Tong float
-- Lấy mã hóa đơn đang thao tác
WITH tmp AS (
	SELECT MaHD FROM inserted
	UNION
	SELECT MaHD FROM deleted
	)
	--SELECT @MaHD = MaHD FROM tmp
-- Tính tổng tiền theo hóa đon đó
	SELECT @Tong = SUM(SoLuong *DonGia * (1-GiamGia))
	FROM ChiTietHD
	WHERE MaHD = @MaHD
-- Cập nhật cột tổng tiền ở hóa đơn ứng với hóa đon đó
	UPDATE HoaDon
	SET TongTien  = @Tong
	WHERE MaHD = @MaHD
END
-- Demo
SELECT * FROM HoaDon WHERE MaHD = 10250
SELECT * FROM ChiTietHD WHERE MaHD = 10250
SELECT * FROM HangHoa WHERE MaHH =1002
INSERT INTO ChiTietHD(MaHD,MaHH, SoLuong, DonGia, GiamGia) VALUES (10250, 1002, 2, 190,0)
Alter table HoaDon add TongTien float

