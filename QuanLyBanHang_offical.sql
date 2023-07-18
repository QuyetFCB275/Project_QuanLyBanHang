----------Ngôn ngữ định nghĩa dữ liệu (Data Definition Language)----------

--1, Tạo các quan hệ và khai báo các khóa chính, khóa ngoại của quan hệ.

-- Quan hệ KHACHHANG:
create table KHACHHANG
(
	MAKH char(4),
	HOTEN varchar(40),
	DIACHI varchar(50),
	SDT varchar(20),
	NGAYSINH smalldatetime,
	DOANHSO money,
	NGAYDK smalldatetime
	constraint PK_KHACHHANG primary key (MAKH)
)


-- Quan hệ NHANVIEN:
create table NHANVIEN
(
	MANV char(4),
	HOTEN varchar(40),
	SDT varchar(20),
	NGAYVL smalldatetime,
	constraint PK_NHANVIEN primary key (MANV)
)


-- Quan hệ SANPHAM:
create table SANPHAM
(
	MASP char(4),
	TENSP varchar(40),
	DVT varchar(20),
	NUOCSX varchar(40),
	GIA money
	constraint PK_SANPHAM primary key (MASP)
)


-- Quan hệ HOADON:
create table HOADON
(
	SOHD int,
	NGHD smalldatetime,
	MAKH char(4),
	MANV char(4),
	TRIGIA money
	constraint PK_HOADON primary key (SOHD)
)


-- Quan hệ CTHD:
create table CTHD
(
	SOHD int,
	MASP char(4),
	SL int
	constraint PK_CTHD primary key (SOHD, MASP)
)


-- Khóa ngoại:
ALTER TABLE HOADON ADD CONSTRAINT FK_MAKH FOREIGN KEY (MAKH) REFERENCES KHACHHANG (MAKH)
ALTER TABLE HOADON ADD CONSTRAINT FK_MANV FOREIGN KEY (MANV) REFERENCES NHANVIEN (MANV)

ALTER TABLE CTHD ADD CONSTRAINT FK_SOHD FOREIGN KEY (SOHD) REFERENCES HOADON (SOHD)
ALTER TABLE CTHD ADD CONSTRAINT FK_MASP FOREIGN KEY (MASP) REFERENCES SANPHAM (MASP)


--2, Thêm vào thuộc tính GHICHU có kiểu dữ liệu varchar(20) cho quan hệ SANPHAM.
ALTER TABLE SANPHAM
ADD GHICHU varchar(20)

--3, Thêm vào thuộc tính LOAIKH có kiểu dữ liệu là tinyint cho quan hệ KHACHHANG.
ALTER TABLE KHACHHANG
ADD LOAIKH tinyint

--4, Sửa kiểu dữ liệu của thuộc tính GHICHU trong quan hệ SANPHAM thành varchar(100).
ALTER TABLE SANPHAM
ALTER COLUMN GHICHU varchar(100)

--5, Xóa thuộc tính GHICHU trong quan hệ SANPHAM.
ALTER TABLE SANPHAM
DROP COLUMN GHICHU

--6, Làm thế nào để thuộc tính LOAIKH trong quan hệ KHACHHANG có thể lưu các giá trị là :'Vang lai', 'Thuong xuyen', 'Vip',...
ALTER TABLE KHACHHANG
ALTER COLUMN LOAIKH varchar(100)

--7, Đơn vị tính của sản phẩm chỉ có thể là ('cay', 'hop', 'cai', 'quyen', 'chuc').
ALTER TABLE SANPHAM
ADD CONSTRAINT CHK_DVT CHECK (DVT IN ('cay', 'hop', 'cai', 'quyen', 'chuc'))

--8, Giá bán của sản phẩm từ 500 đồng trở lên.
ALTER TABLE SANPHAM
ADD CONSTRAINT CHK_GIA CHECK (GIA >= 500)

--9, Mỗi lần mua hàng, khách hàng phải mua ít nhất 1 sản phẩm.
ALTER TABLE HOADON
ADD CONSTRAINT CHK_TRIGIA CHECK(TRIGIA > 0)

--10, Ngày khách hàng đăng ký là thành viên phải lớn hơn ngày sinh của người đó.
ALTER TABLE KHACHHANG
ADD CONSTRAINT CHK_NGAYDK CHECK(NGAYDK > NGAYSINH)

--11, Ngày mua hàng (NGHD) của một khách hàng là thành viên sẽ lớn hơn hoặc bằng ngày khách hàng đó đăng ký thành viên (NGDK).

CREATE TRIGGER tg_NGHD on HOADON for insert, update
as
begin
	if (select count(*) from inserted, KHACHHANG WHERE inserted.MAKH = KHACHHANG.MAKH and inserted.NGHD < KHACHHANG.NGAYDK) > 0
	begin
		print 'Không hợp lệ: Ngày mua hàng phải lớn hơn hoặc bằng ngày đăng kí'
		rollback transaction
	end
	else
	begin
		print 'Thêm hóa đơn thành công'
	end
end


--12, Ngày bán hàng (NGHD) của một nhân viên phải lớn hơn hoặc bằng ngày nhân viên đó vào làm.

CREATE TRIGGER tg_NGHD_2 on HOADON for insert, update
as
begin
	if (select count(*) from inserted, NHANVIEN where inserted.MANV = NHANVIEN.MANV and inserted.NGHD < NHANVIEN.NGAYVL) > 0
	begin
		print 'Không hợp lệ: Ngày mua hàng phải lớn hơn hoặc bằng ngày đăng kí'
		rollback transaction
	end
	else
	begin
		print 'Thêm hóa đơn thành công'
	end
end


--13, Mỗi một hóa đơn phải có ít nhất một chi tiết hóa đơn.

create trigger tg_HOADON on HOADON for insert, update
as
begin
	if (select count(*) from inserted) > 0
	begin
		print 'Thêm hóa đơn thành công'
	end
	else
	begin
		print 'Lỗi. Hóa đơn phải tồn tại ít nhất một chi tiết hóa đơn.'
	end
end


--14, Trị giá của một hóa đơn là tổng thành tiền (số lượng * đơn giá) của các chi tiết thuộc hóa đơn đó.

CREATE TRIGGER tg_CTHD1 on CTHD for insert, update, delete
as
begin
		update HOADON set TRIGIA = 
		(
				select sum(SL*GIA)
				from SANPHAM, CTHD
				where SANPHAM.MASP = CTHD.MASP and CTHD.SOHD = HOADON.SOHD
		)
		where HOADON.SOHD in (select SOHD from inserted)
end


--15, Doanh số của một khách hàng là tổng giá trị các hóa đơn mà khách hàng thành viên đó đã mua.

CREATE TRIGGER tg_HOADON2 on HOADON for insert, update, delete
as
begin
	update KHACHHANG set DOANHSO = 
	(
		select sum(TRIGIA) from HOADON
	)
	where KHACHHANG.MAKH in (select MAKH from inserted)
end


----------Ngôn ngữ thao tác dữ liệu (Data Manipulation Language)----------

--1, Nhập dữ liệu cho các quan hệ trên.

-- Nhập dữ liệu cho quan hệ NHANVIEN

INSERT INTO NHANVIEN VALUES ('NV01', 'Nguyen Nhu Nhut', '0927345678', '2006-04-13')
INSERT INTO NHANVIEN VALUES ('NV02', 'Le Thi Phi Yen', '0987567390', '2006/04/21')
INSERT INTO NHANVIEN VALUES ('NV03', 'Nguyen Van B', '0997047382','2006/04/27' )
INSERT INTO NHANVIEN VALUES ('NV04', 'Ngo Thanh Tuan', '0913758498', '2006/06/24')
INSERT INTO NHANVIEN VALUES ('NV05', 'Nguyen Thi Truc Thanh', '0918590387', '2006/07/20')


-- Nhập dữ liệu cho quan hệ KHACHHANG

-- Phải xóa cột LOAIKH trước
ALTER TABLE KHACHHANG
DROP COLUMN LOAIKH


INSERT INTO KHACHHANG VALUES('KH01','Nguyen Van A','731 Tran Hung Dao, Q5, TpHCM','08823451','1960/10/22',13060000,'2006/7/22')
INSERT INTO KHACHHANG VALUES('KH02','Tran Ngoc Han','23/5 Nguyen Trai, Q5, TpHCM','908256478','1974/04/03',280000,'2006/7/30')
INSERT INTO KHACHHANG VALUES('KH03','Tran Ngoc Linh','45 Nguyen Canh Chan, Q1, TpHCM','938776266','1980/06/12',3860000,'2006/5/8')
INSERT INTO KHACHHANG VALUES('KH04','Tran Minh Long','50/34 Le Dai Hanh, Q10, TpHCM','917325476','1965/03/09',250000,'2006/2/10')
INSERT INTO KHACHHANG VALUES('KH05','Le Nhat Minh','34 Truong Dinh, Q3, TpHCM','8246108','1950/03/10',21000,'2006/10/28')
INSERT INTO KHACHHANG VALUES('KH06','Le Hoai Thuong','227 Nguyen Van Cu, Q5, TpHCM','8631738','1981/12/31',915000,'2006/11/24')
INSERT INTO KHACHHANG VALUES('KH07','Nguyen Van Tam','32/3 Tran Binh Trong, Q5, TpHCM','916783565','1971/4/6',12500,'2006/1/12')
INSERT INTO KHACHHANG VALUES('KH08','Phan Thi Thanh','45/2 An Duong Vuong, Q5, TpHCM','938435756','1971/1/10',365000,'2006/12/13')
INSERT INTO KHACHHANG VALUES('KH09','Le Ha Vinh','873 Le Hong Phong, Q5, TpHCM','8654763','1979/9/3',70000,'2007/1/14')
INSERT INTO KHACHHANG VALUES('KH10','Ha Duy Lap','34/34B Nguyen Trai, Q1, TpHCM','8768904','1983/5/2',67500,'2007/1/16')


-- Nhập dữ liệu cho quan hệ SANPHAM

insert into SANPHAM values('BC01','But chi','cay','Singapore',3000)
insert into SANPHAM values('BC02','But chi','cay','Singapore',5000)
insert into SANPHAM values('BC03','But chi','cay','Viet Nam',3500)
insert into SANPHAM values('BC04','But chi','hop','Viet Nam',30000)
insert into SANPHAM values('BB01','But bi','cay','Viet Nam',5000)
insert into SANPHAM values('BB02','But bi','cay','Trung Quoc',7000)
insert into SANPHAM values('BB03','But bi','hop','Thai Lan',100000)
insert into SANPHAM values('TV01','Tap 100 giay mong','quyen','Trung Quoc',2500)
insert into SANPHAM values('TV02','Tap 200 giay mong','quyen','Trung Quoc',4500)
insert into SANPHAM values('TV03','Tap 100 giay tot','quyen','Viet Nam',3000)
insert into SANPHAM values('TV04','Tap 200 giay tot','quyen','Viet Nam',5500)
insert into SANPHAM values('TV05','Tap 100 trang','chuc','Viet Nam',23000)
insert into SANPHAM values('TV06','Tap 200 trang','chuc','Viet Nam',53000)
insert into SANPHAM values('TV07','Tap 100 trang','chuc','Trung Quoc',34000)
insert into SANPHAM values('ST01','So tay 500 trang','quyen','Trung Quoc',40000)
insert into SANPHAM values('ST02','So tay loai 1','quyen','Viet Nam',55000)
insert into SANPHAM values('ST03','So tay loai 2','quyen','Viet Nam',51000)
insert into SANPHAM values('ST04','So tay','quyen','Thai Lan',55000)
insert into SANPHAM values('ST05','So tay mong','quyen','Thai Lan',20000)
insert into SANPHAM values('ST06','Phan viet bang','hop','Viet Nam',5000)
insert into SANPHAM values('ST07','Phan khong bui','hop','Viet Nam',7000)
insert into SANPHAM values('ST08','Bong bang','cai','Viet Nam',1000)
insert into SANPHAM values('ST09','But long','cay','Viet Nam',5000)
insert into SANPHAM values('ST10','But long','cay','Trung Quoc',7000)



-- Nhập dữ liệu cho quan hệ HOADON

insert into HOADON values(1001,'2006/7/23','KH01','NV01',320000)
insert into HOADON values(1002,'2006/8/12','KH01','NV02',840000)
insert into HOADON values(1003,'2006/8/23','KH02','NV01',100000)
insert into HOADON values(1004,'2006/9/1','KH02','NV01',180000)
insert into HOADON values(1005,'2006/10/20','KH01','NV02',3800000)
insert into HOADON values(1006,'2006/10/16','KH01','NV03',2430000)
insert into HOADON values(1007,'2006/10/28','KH03','NV03',510000)
insert into HOADON values(1008,'2006/10/28','KH01','NV03',440000)
insert into HOADON values(1009,'2006/10/28','KH03','NV04',200000)
insert into HOADON values(1010,'2006/11/1','KH01','NV01',5200000)
insert into HOADON values(1011,'2006/11/4','KH04','NV03',250000)
insert into HOADON values(1012,'2006/11/30','KH05','NV03',21000)
insert into HOADON values(1013,'2006/12/12','KH06','NV01',5000)
insert into HOADON values(1014,'2006/12/31','KH03','NV02',3150000)
insert into HOADON values(1015,'2007/1/1','KH06','NV01',910000)
insert into HOADON values(1016,'2007/1/1','KH07','NV02',12500)
insert into HOADON values(1017,'2007/1/2','KH08','NV03',35000)
insert into HOADON values(1018,'2007/1/13','KH08','NV03',330000)
insert into HOADON values(1019,'2007/1/13','KH01','NV03',30000)
insert into HOADON values(1020,'2007/1/14','KH09','NV04',70000)
insert into HOADON values(1021,'2007/1/16','KH10','NV03',67500)
insert into HOADON values(1022,'2007/1/16',Null,'NV03',7000)
insert into HOADON values(1023,'2007/1/17',Null,'NV01',330000)


-- Nhập dữ liệu cho quan hệ CTHD

insert into CTHD values(1001,'TV02',10)
insert into CTHD values(1001,'ST01',5)
insert into CTHD values(1001,'BC01',5)
insert into CTHD values(1001,'BC02',10)
insert into CTHD values(1001,'ST08',10)
insert into CTHD values(1002,'BC04',20)
insert into CTHD values(1002,'BB01',20)
insert into CTHD values(1002,'BB02',20)
insert into CTHD values(1003,'BB03',10)
insert into CTHD values(1004,'TV01',20)
insert into CTHD values(1004,'TV02',10)
insert into CTHD values(1004,'TV03',10)
insert into CTHD values(1004,'TV04',10)
insert into CTHD values(1005,'TV05',50)
insert into CTHD values(1005,'TV06',50)
insert into CTHD values(1006,'TV07',20)
insert into CTHD values(1006,'ST01',30)
insert into CTHD values(1006,'ST02',10)
insert into CTHD values(1007,'ST03',10)
insert into CTHD values(1008,'ST04',8)
insert into CTHD values(1009,'ST05',10)
insert into CTHD values(1010,'TV07',50)
insert into CTHD values(1010,'ST07',50)
insert into CTHD values(1010,'ST08',100)
insert into CTHD values(1010,'ST04',50)
insert into CTHD values(1010,'TV03',100)
insert into CTHD values(1011,'ST06',50)
insert into CTHD values(1012,'ST07',3)
insert into CTHD values(1013,'ST08',5)
insert into CTHD values(1014,'BC02',80)
insert into CTHD values(1014,'BB02',100)
insert into CTHD values(1014,'BC04',60)
insert into CTHD values(1014,'BB01',50)
insert into CTHD values(1015,'BB02',30)
insert into CTHD values(1015,'BB03',7)
insert into CTHD values(1016,'TV01',5)
insert into CTHD values(1017,'TV02',1)
insert into CTHD values(1017,'TV03',1)
insert into CTHD values(1017,'TV04',5)
insert into CTHD values(1018,'ST04',6)
insert into CTHD values(1019,'ST05',1)
insert into CTHD values(1019,'ST06',2)
insert into CTHD values(1020,'ST07',10)
insert into CTHD values(1021,'ST08',5)
insert into CTHD values(1021,'TV01',7)
insert into CTHD values(1021,'TV02',10)
insert into CTHD values(1022,'ST07',1)
insert into CTHD values(1023,'ST04',6)


--2, Tạo quan hệ SANPHAM1 chứa toàn bộ dữ liệu của quan hệ SANPHAM. Tạo quan hệ KHACHHANG1 chứa toàn bộ dữ liệu của quan hệ KHACHHANG.

SELECT * INTO SANPHAM1 FROM SANPHAM
SELECT * INTO KHACHHANG1 FROM KHACHHANG

--3, Cập nhật giá tăng 5% đối với những sản phẩn do 'Thái Lan ' sản xuất trong quan hệ SANPHAM1.
UPDATE SANPHAM1 SET GIA = GIA * 1.05 WHERE NUOCSX = 'Thai Lan'

--4, Cập nhật giá giảm 5% đối với những sản phẩm do 'Trung Quốc' sản xuất có giá từ 10.000 đồng trở xuống (cho quan hệ SANPHAM1).
UPDATE SANPHAM1 SET GIA = GIA * 0.95 WHERE NUOCSX = 'Trung Quoc' AND GIA <= 10000

--5, Cập nhật giá trị LOAIKH là “Vip” đối với những khách hàng đăng ký thành viên trước ngày 1/1/2007 có doanh số từ 10.000.000 trở lên hoặc khách hàng đăng ký thành viên từ 1/1/2007 trở về sau có doanh số từ 2.000.000 trở lên (cho quan hệ KHACHHANG1).

--Đã xóa trường LOAIKH ở trên nên phải thêm trường này cho cả 2 bảng
ALTER TABLE KHACHHANG
ADD LOAIKH varchar(100)

ALTER TABLE KHACHHANG1
ADD LOAIKH varchar(100)

UPDATE KHACHHANG1 SET LOAIKH = 'Vip' where (NGAYDK < '2007/1/1' and DOANHSO >= 10000000) or (NGAYDK >= '2007/1/1' AND DOANHSO >= 2000000)


/* Chú ý: Từ đây các câu lệnh SQL sẽ viết in thường lower case */


----------Ngôn ngữ truy vấn dữ liệu---------

-- Câu 1, In ra danh sách các sản phẩm (MASP, TENSP) do 'Trung Quóc' sản xuất.
select MASP, TENSP from SANPHAM where NUOCSX = 'Trung Quoc'

-- Câu 2, In ra danh sách các sản phẩm (MASP, TENSP) có đơn vị tính là 'cay', 'quyen'.
select MASP, TENSP from SANPHAM where DVT in ('cay', 'quyen')

-- Câu 3, In ra danh sách các sản phẩm (MASP, TENSP) có mã sản phẩm bắt đầu là 'B' và kết thúc là '01'.
select MASP, TENSP from SANPHAM where MASP like 'B%01'

-- Câu 4, In ra danh sách các sản phẩm (MASP, TENSP) do 'Trung Quoc' sản xuất có giá từ 30,000 đồng đến 40,000.
select MASP, TENSP from SANPHAM where NUOCSX = 'Trung Quoc' and GIA between 30000 and 40000

-- Câu 5, In ra danh sách các sản phẩm (MASP, TENSP) do 'Trung Quoc' hoặc 'Thái Lan' sản xuất có giá từ 30,000 đến 40,000.
select MASP, TENSP from SANPHAM where NUOCSX in ('Trung Quoc', 'Thai Lan') and GIA between 30000 and 40000


-- Câu 6, In ra các số hóa đơn, trị giá hóa đơn bán ra trong ngày 1/1/2007 và ngày 2/1/2007
select SOHD, TRIGIA from HOADON where NGHD in ('2007/1/1', '2007/1/2')

--Câu 7, In ra các số hóa đơn, trị giá hóa đơn trong tháng 1/2007, sắp xếp theo ngày tăng dần và trị giá của hóa đơn giảm dần
select SOHD, TRIGIA from HOADON where month(NGHD) = 1 and year(NGHD) = 2007 order by NGHD asc, TRIGIA desc

-- Câu 8, In ra danh sách các khách hàng (MAKH, HOTEN) đã mua hàng trong ngày 1/1/2007
select KHACHHANG.MAKH, HOTEN
from KHACHHANG inner join HOADON on KHACHHANG.MAKH = HOADON.MAKH
where NGHD = '2007/1/1'

-- Câu 9, In ra số hóa đơn, trị giá các hóa đơn do nhân viên có tên 'Nguyen Van B' lập trong ngày 28/10/2006
select SOHD, TRIGIA
from NHANVIEN inner join HOADON on NHANVIEN.MANV = HOADON.MANV
where HOTEN = 'Nguyen Van B' and NGHD = '2006/10/28'

-- Câu 10, In ra danh sách các sản phẩm (MASP, TENSP) được khách hàng có tên 'Nguyen Van A' mua trong tháng 10/2006
select SANPHAM.MASP, SANPHAM.TENSP
from SANPHAM
where exists (
    select *
    from CTHD, HOADON, KHACHHANG
    where SANPHAM.MASP = CTHD.MASP
    and CTHD.SOHD = HOADON.SOHD
    and HOADON.MAKH = KHACHHANG.MAKH
    and KHACHHANG.HOTEN = 'Nguyen Van A'
    and HOADON.NGHD between '2006/10/1' and '2006/10/31'
)

-- Câu 11, Tìm các số hóa đơn đã mua sản phẩm có mã số 'BB01' hoặc 'BB02'
select SOHD from CTHD where MASP in ('BB01', 'BB02')

-- Câu 12, Tìm các số hóa đơn đã mua sản phẩm có mã số 'BB01' hoặc 'BB02', mỗi sản phẩm mua với số lượng từ 10 đến 20
select SOHD from CTHD where MASP = 'BB01' and SL between 10 and 20
union
select SOHD from CTHD where MASP = 'BB02' and SL between 10 and 20

-- Câu 13, Tìm các số hóa đơn đã mua cùng lúc 2 sản phẩm có mã số 'BB01' và 'BB02', mỗi sản phẩm mua với số lượng từ 10 đến 20.
select SOHD from CTHD
where MASP = 'BB01'
and exists (select * from CTHD where CTHD.SOHD = SOHD and MASP = 'BB02')
and SL between 10 and 20

/*( Giải thích: truy vấn kiểm tra mỗi SOHD có sp có mã 'BB01' có tồn tại 1 sp khác có mã là 'BB02' hay không
nhờ câu lệnh exists và liên kết trong subquery CTHD.SOHD = SOHD, nếu bỏ liên kết này thì truy vấn sẽ 
trở thành kiểm tra mỗi SOHD có sp có mã 'BB01' có tồn tại 1 SOHD (nào đó, có thể là chính nó) có sp có mã là 'BB02' hay không)*/
--! Nếu không có liên kết này thì cứ SOHD nào có sp có mã 'BB01' đề sẽ đc return do where exists luôn đúng vì CTHD có tồn tại mã 'BB02'

-- Câu 14, In ra danh sách các sản phẩm (MASP, TENSP) do 'Trung Quốc' sản xuất hoặc được bán ra trong ngày 1/1/2007.
select MASP, TENSP from SANPHAM where NUOCSX = 'Trung Quoc'
union
select MASP, TENSP from SANPHAM
where exists (
		select * from CTHD 
		where SANPHAM.MASP = CTHD.MASP
		and exists (select * from HOADON where CTHD.SOHD = HOADON.SOHD and NGHD = '2007/1/1')
	)

-- Câu 15, In ra danh sách các sản phẩm (MASP, TENSP) không bán được.
select MASP, TENSP from SANPHAM
where MASP not in (select distinct MASP from CTHD)

-- Câu 16, In ra danh sách các sản phẩm (MASP, TENSP) không bán được trong năm 2006.
select MASP, TENSP from SANPHAM
where MASP not in (
select MASP from CTHD
where exists (select * from HOADON where CTHD.SOHD = HOADON.SOHD and year(NGHD) = '2006'))

-- Câu 17, In ra danh sách các sản phẩm (MASP, TENSP) do 'Trung Quốc' sản xuất không bán được trong năm 2006.
select MASP, TENSP from SANPHAM
where MASP not in (
select MASP from CTHD
where exists (select * from HOADON where CTHD.SOHD = HOADON.SOHD and year(NGHD) = '2006'))
and NUOCSX = 'Trung Quoc'

-- Câu 18, Tìm số hóa đơn đã mua tất cả các sản phẩm do Singapore sản xuất
select SOHD, count(CTHD.MASP) as [Tong san pham]
from CTHD, SANPHAM
where CTHD.MASP = SANPHAM.MASP and NUOCSX = 'Singapore'
group by CTHD.SOHD
having count(distinct CTHD.MASP) = (select count(*) from SANPHAM where NUOCSX = 'Singapore')

-- Giải thích: Lựa chọn tất cả các SOHD mà có MASP do Singapore sản xuất, sau đó group by theo SOHD,
--nếu SOHD nào mà có số lượng sp khác nhau bằng đúng số lượng sản phẩm do Singapore sản xuất thì return

-- Câu 19, Tìm số hóa đơn trong năm 2006 đã mua ít nhất tất cả các sản phẩm do Singapore sản xuất.
select SOHD
from HOADON
where YEAR(NGHD) = 2006 
and not exists
(
	select *
	from SANPHAM
	where NUOCSX = 'Singapore'
	and not exists
	(
		select *
		from CTHD
		where CTHD.SOHD = HOADON.SOHD
		and CTHD.MASP = SANPHAM.MASP
	)
)

-- Câu 20, Có bao nhiêu hóa đơn không phải của khách hàng đăng ký thành viên mua?
select count(distinct SOHD) as TongKH from HOADON  where MAKH is null

-- Câu 21, Có bao nhiêu sản phẩm khác nhau được bán ra trong năm 2006.
select count(distinct MASP)  from HOADON, CTHD where year(NGHD) = '2006'

-- Câu 22, Cho biết trị giá hóa đơn cao nhất, thấp nhất là bao nhêu?
select max(TRIGIA) from HOADON
select min(TRIGIA) from HOADON

-- Câu 23, Trị giá trung bình của tất cả các hóa đơn được bán ra trong năm 2006 là bao nhiêu?
select avg(TRIGIA) from HOADON where year(NGHD) = '2006'

-- Câu 24, Tính doanh thu bán hàng trong năm 2006.
select sum(TRIGIA) from HOADON where year(NGHD) = '2006'

-- Câu 25, Tìm số hóa đơn có trị giá cao nhất trong năm 2006.
select SOHD from HOADON where TRIGIA = (select max(TRIGIA) from HOADON where year(NGHD) = '2006')

-- Câu 26, Tìm họ tên khách hàng đã mua hóa đơn có trị giá cao nhất trong năm 2006.
select HOTEN from KHACHHANG inner join HOADON on KHACHHANG.MAKH = HOADON.MAKH 
where year(NGHD) = '2006' and TRIGIA = (select max(TRIGIA) from HOADON)

-- Câu 27, In ra danh sách 3 khách hàng đầu tiên (MAKH, HOTEN) sắp xếp theo doanh số giảm dần.
select top 3 MAKH, HOTEN from KHACHHANG order by DOANHSO desc

-- Câu 28, In ra danh sách các sản phẩm (MASP, TENSP) có giá bán bằng 1 trong 3 mức giá cao nhất.
select MASP, TENSP from SANPHAM 
where GIA in (select distinct top 3 GIA from SANPHAM order by GIA desc)

-- Câu 29, In ra danh sách các sản phẩm  (MASP, TENSP) do 'Thai Lan' sản xuất có giá bằng 1 trong 3 mức giá cao nhất (của tất cả các sản phẩm).
select MASP, TENSP from SANPHAM
where NUOCSX = 'Thai Lan'
and GIA in (select distinct top 3 GIA from SANPHAM order by GIA desc)

-- Câu 30, In ra danh sách các sản phẩm (MASP, TENSP) do 'Trung Quốc' sản xuất có giá bằng 1 trong 3 mức giá cao nhất (của sản phẩm do 'Trung Quốc' sản xuất).
select MASP, TENSP from SANPHAM
where NUOCSX = 'Trung Quoc'
and GIA in (select distinct top 3 GIA from SANPHAM where NUOCSX = 'Trung Quoc' order by GIA desc)

-- Câu 31, In ra danh sách khách hàng nằm trong 3 hạng cao nhất (xếp hạng theo doanh số).
select top 3 * from KHACHHANG order by DOANHSO desc

-- Câu 32, Tính tổng số sản phẩm do 'Trung Quốc' sản xuất.
select count(*) from SANPHAM where NUOCSX = 'Trung Quoc' 

-- Câu 33, Tính tổng số sản phẩm của từng nước sản xuất.
select NUOCSX, count(*) as [Tong san pham] from SANPHAM group by NUOCSX

-- Câu 34, Với từng nước sản xuất, tìm giá bán cao nhất, thấp nhất, trung bình của các sản phẩm.
select NUOCSX, max(GIA) as GIACAONHAT, min(GIA) as GIATHAPNHAT, avg(GIA) as GIATB from SANPHAM group by NUOCSX

-- Câu 35, Tính doanh thu bán hàng mỗi ngày.
select NGHD, sum(TRIGIA) as [DOANH THU] from HOADON group by NGHD

-- Câu 36, Tính tổng số lượng của từng sản phẩm bán ra trong tháng 10/2006.
select CTHD.MASP, SANPHAM.TENSP, sum(SL) as [So luong]
from CTHD, SANPHAM where CTHD.MASP = SANPHAM.MASP and exists (select * from HOADON where CTHD.SOHD = HOADON.SOHD and year(NGHD) = '2006' and month(NGHD) = '10')
group by CTHD.MASP, SANPHAM.TENSP

-- Câu 37, Tính doanh thu bán hàng của từng tháng trong năm 2006.
select month(NGHD) as [Thang], sum(TRIGIA) as [Tong gia tri] from HOADON where year(NGHD) = '2006' group by month(NGHD)

-- Câu 38, Tìm hóa đơn mua ít nhất 4 sản phẩm khác nhau
select SOHD, count(MASP) as [So san pham] from CTHD
group by SOHD
having count(MASP) >= 4
order by count(MASP) desc

-- Câu 39, Tìm hóa đơn có mua 3 sản phẩm khác nhau do 'Viet Nam' sản xuất.
select SOHD, count(MASP) as [Sum product made in VN]
from CTHD
where exists (select * from SANPHAM where CTHD.MASP = SANPHAM.MASP and NUOCSX = 'Viet Nam')
group by SOHD
having count(MASP) >= 3

-- Câu 40, Tìm khách hàng (MAKH, HOTEN) có số lượng mua hàng nhiều nhất.
select MAKH, HOTEN from KHACHHANG
where MAKH = (select top 1 MAKH from HOADON group by MAKH  order by count(SOHD) desc)

-- Câu 41, Tháng mấy trong năm 2006, doanh số bán hàng cao nhất?
select top 1 month(NGHD) as [Thang], sum(TRIGIA) as [Doanh so] 
from HOADON where year(NGHD) = '2006'
group by month(NGHD)
order by sum(TRIGIA) desc

-- Câu 42, Tìm sản phẩm (MASP, TENSP) có tổng số lượng bán ra thấp nhất trong năm 2006.
select MASP, TENSP from SANPHAM
where MASP = (select top 1 MASP from CTHD inner join HOADON on CTHD.SOHD = HOADON.SOHD
			where year(NGHD) = '2006'  group by MASP order by sum(SL) asc)

-- Câu 43, Với mỗi nước sản xuất, tìm sản phẩm (MASP, TENSP) có giá bán cao nhất.
select NUOCSX, max(GIA) as [Gia ban lon nhat] from SANPHAM group by NUOCSX

-- Câu 44, Tìm các nước sản xuất ít nhất 3 sản phẩm có giá bán khác nhau.
select NUOCSX, count (distinct GIA) as [San pham] from SANPHAM
group by NUOCSX
having count (distinct GIA) >= 3

-- Câu 45, Trong 10 khách hàng có doanh số cao nhất, tìm khách hàng có số lần mua nhiều nhất.
select MAKH, HOTEN from KHACHHANG
where MAKH = (select top 1 MAKH from HOADON group by MAKH order by count(SOHD) desc)