-- DropForeignKey
ALTER TABLE "Payment" DROP CONSTRAINT "Payment_orderId_fkey";

-- AlterTable
ALTER TABLE "Payment" ADD COLUMN     "rentalBookingId" TEXT,
ALTER COLUMN "orderId" DROP NOT NULL;

-- AlterTable
ALTER TABLE "RentalShopProfile" ADD COLUMN     "stripeAccountId" TEXT;

-- AlterTable
ALTER TABLE "TailorProfile" ADD COLUMN     "stripeAccountId" TEXT;

-- CreateIndex
CREATE UNIQUE INDEX "Payment_rentalBookingId_key" ON "Payment"("rentalBookingId");

-- CreateIndex
CREATE UNIQUE INDEX "RentalShopProfile_stripeAccountId_key" ON "RentalShopProfile"("stripeAccountId");

-- CreateIndex
CREATE UNIQUE INDEX "TailorProfile_stripeAccountId_key" ON "TailorProfile"("stripeAccountId");

-- AddForeignKey
ALTER TABLE "Payment" ADD CONSTRAINT "Payment_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "CustomOrder"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Payment" ADD CONSTRAINT "Payment_rentalBookingId_fkey" FOREIGN KEY ("rentalBookingId") REFERENCES "RentalBooking"("id") ON DELETE SET NULL ON UPDATE CASCADE;

