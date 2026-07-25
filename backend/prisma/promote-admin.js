// One-off provisioning script: promotes an existing user to Role.ADMIN.
// There's no signup flow for admins — they must already have signed in at
// least once (via POST /auth/firebase) so their User row exists, then get
// promoted here.
//
// Usage: npm run seed:admin -- someone@example.com

const { PrismaClient, Role } = require('@prisma/client');

async function main() {
  const email = process.argv[2];
  if (!email) {
    console.error('Usage: npm run seed:admin -- <email>');
    process.exit(1);
  }

  const prisma = new PrismaClient();
  try {
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) {
      console.error(
        `No user found with email "${email}". They must sign in at least ` +
          'once via POST /auth/firebase before they can be promoted.',
      );
      process.exit(1);
    }

    if (user.role === Role.ADMIN) {
      console.log(`${email} is already Role.ADMIN — nothing to do.`);
      return;
    }

    const updated = await prisma.user.update({
      where: { email },
      data: { role: Role.ADMIN },
    });
    console.log(`Promoted ${updated.email} (${updated.id}) to Role.ADMIN.`);
  } finally {
    await prisma.$disconnect();
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
