-- DropForeignKey
ALTER TABLE "CustomOrder" DROP CONSTRAINT "CustomOrder_measurementId_fkey";

-- AddForeignKey
ALTER TABLE "CustomOrder" ADD CONSTRAINT "CustomOrder_measurementId_fkey" FOREIGN KEY ("measurementId") REFERENCES "Measurement"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
