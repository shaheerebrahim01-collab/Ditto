-- CreateEnum
CREATE TYPE "VisitRequestStatus" AS ENUM ('PENDING', 'ASSIGNED', 'COMPLETED', 'CANCELLED');

-- CreateTable
CREATE TABLE "MeasurementVisitRequest" (
    "id" TEXT NOT NULL,
    "customerId" TEXT NOT NULL,
    "location" TEXT NOT NULL,
    "preferredAt" TIMESTAMP(3) NOT NULL,
    "notes" TEXT,
    "status" "VisitRequestStatus" NOT NULL DEFAULT 'PENDING',
    "tailorId" TEXT,
    "assistantId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "MeasurementVisitRequest_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "MeasurementVisitRequest" ADD CONSTRAINT "MeasurementVisitRequest_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MeasurementVisitRequest" ADD CONSTRAINT "MeasurementVisitRequest_tailorId_fkey" FOREIGN KEY ("tailorId") REFERENCES "TailorProfile"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MeasurementVisitRequest" ADD CONSTRAINT "MeasurementVisitRequest_assistantId_fkey" FOREIGN KEY ("assistantId") REFERENCES "TailorAssistant"("id") ON DELETE SET NULL ON UPDATE CASCADE;
