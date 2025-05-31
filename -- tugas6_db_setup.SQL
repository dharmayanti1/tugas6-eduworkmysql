-- tugas6_db_setup.sql

-- ================================================
-- PENGGUNAAN DATABASE
-- ================================================

USE tugas6;

-- ================================================
-- TABEL
-- ================================================

-- Tabel Products
CREATE TABLE products (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nama_produk VARCHAR(255) NOT NULL,
    harga DECIMAL(10,2) NOT NULL CHECK (harga > 0),
    deskripsi TEXT,
    stok INT NOT NULL DEFAULT 0 CHECK (stok >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Tabel Users
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nama VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL COMMENT 'Hash password (misal SHA256/bcrypt), bukan plain text',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_email CHECK (email LIKE '%@%.%')
) ENGINE=InnoDB;

-- Tabel Orders
CREATE TABLE orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('pending', 'paid', 'shipped', 'delivered', 'cancelled') DEFAULT 'pending',
    total DECIMAL(10,2) NOT NULL CHECK (total >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Tabel Order Items
CREATE TABLE order_items (
    id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    harga_satuan DECIMAL(10,2) NOT NULL CHECK (harga_satuan >= 0),
    subtotal DECIMAL(10,2) GENERATED ALWAYS AS (quantity * harga_satuan) STORED,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Tabel Audit Perubahan Harga Produk
CREATE TABLE product_price_audit (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    old_price DECIMAL(10,2) NOT NULL,
    new_price DECIMAL(10,2) NOT NULL,
    changed_by VARCHAR(255),
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id)
) ENGINE=InnoDB;

-- ================================================
-- TRIGGER AUDIT PERUBAHAN HARGA PRODUK
-- ================================================

DELIMITER //
CREATE TRIGGER before_product_price_update
BEFORE UPDATE ON products
FOR EACH ROW
BEGIN
    IF NEW.harga <> OLD.harga THEN
        INSERT INTO product_price_audit (product_id, old_price, new_price, changed_by)
        VALUES (OLD.id, OLD.harga, NEW.harga, CURRENT_USER());
    END IF;
END //
DELIMITER ;

-- ================================================
-- VIEW LAPORAN PENJUALAN
-- ================================================

CREATE VIEW sales_report AS
SELECT 
    DATE(o.order_date) AS tanggal,
    COUNT(DISTINCT o.order_id) AS jumlah_transaksi,
    SUM(o.total) AS total_penjualan,
    SUM(oi.quantity) AS jumlah_barang_terjual,
    COUNT(DISTINCT o.user_id) AS jumlah_pembeli
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'delivered'
GROUP BY DATE(o.order_date);

-- ================================================
-- INDEX UNTUK OPTIMASI QUERY
-- ================================================

CREATE INDEX idx_product_name ON products(nama_produk);
CREATE INDEX idx_product_price ON products(harga);
CREATE INDEX idx_user_email ON users(email);
CREATE INDEX idx_order_date_status ON orders(order_date, status);
CREATE INDEX idx_order_user ON orders(user_id);
CREATE INDEX idx_order_item_product ON order_items(product_id);
CREATE INDEX idx_order_item_order ON order_items(order_id);

-- ================================================
-- DATA DUMMY
-- ================================================

-- Users
INSERT INTO users (nama, email, password) VALUES
('Dharma Yanti', 'dharma@example.com', 'hashed_password1'),
('Ayu Lestari', 'ayu@example.com', 'hashed_password2');

-- Products
INSERT INTO products (nama_produk, harga, deskripsi, stok) VALUES
('Pulpen Pilot', 12000, 'Pulpen tinta gel warna hitam', 100),
('Buku Tulis Sidu', 8000, 'Buku tulis 40 lembar', 200),
('Kalkulator Casio', 150000, 'Kalkulator scientific 991ES', 50);

-- Orders
INSERT INTO orders (user_id, status, total) VALUES
(1, 'delivered', 18000),
(2, 'paid', 150000);

-- Order Items
INSERT INTO order_items (order_id, product_id, quantity, harga_satuan) VALUES
(1, 1, 1, 12000),
(1, 2, 1, 6000),
(2, 3, 1, 150000);
