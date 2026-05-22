-- CreateIndex
CREATE INDEX "ClientePago_cliente_id_idx" ON "ClientePago"("cliente_id");

-- CreateIndex
CREATE INDEX "Pedido_createdAt_idx" ON "Pedido"("createdAt");

-- CreateIndex
CREATE INDEX "Pedido_cliente_id_idx" ON "Pedido"("cliente_id");

-- CreateIndex
CREATE INDEX "PedidoItem_pedido_id_idx" ON "PedidoItem"("pedido_id");

-- CreateIndex
CREATE INDEX "PedidoItem_producto_id_idx" ON "PedidoItem"("producto_id");

-- CreateIndex
CREATE INDEX "Producto_cat_id_idx" ON "Producto"("cat_id");
