type Row = Record<string, any>;

function table(uniqueKeys: string[] = []) {
  const rows: Row[] = [];
  const matches = (r: Row, where: Row = {}): boolean =>
    Object.entries(where).every(([k, v]) => {
      if (k === 'OR') return (v as Row[]).some((w) => matches(r, w));
      if (v && typeof v === 'object' && 'notIn' in v) return !v.notIn.includes(r[k]);
      return r[k] === v;
    });
  return {
    rows,
    create: async ({ data }: Row) => {
      for (const k of uniqueKeys) {
        if (data[k] != null && rows.some((r) => r[k] === data[k])) throw new Error('unique');
      }
      const row = { id: `00000000-0000-4000-8000-${String(rows.length + 1).padStart(12, '0')}`, createdAt: new Date(), hidden: false, ...data };
      rows.push(row);
      return row;
    },
    findFirst: async ({ where }: Row) => rows.find((r) => matches(r, where)) ?? null,
    findUnique: async ({ where }: Row) => rows.find((r) => matches(r, where)) ?? null,
    findMany: async ({ where, take }: Row = {}) => rows.filter((r) => matches(r, where)).slice(0, take),
    delete: async ({ where }: Row) => {
      const i = rows.findIndex((r) => matches(r, where));
      return rows.splice(i, 1)[0];
    },
    deleteMany: async ({ where }: Row) => {
      for (let i = rows.length - 1; i >= 0; i--) if (matches(rows[i], where)) rows.splice(i, 1);
    },
  };
}

export const db = {
  user: table(['email', 'phone']),
  refreshToken: table(['tokenHash']),
  post: Object.assign(table(), {}),
  block: table(),
  like: table(),
  notification: table(),
  knowledgeEntry: table(),
};

export function resetDb() {
  Object.values(db).forEach((t) => (t.rows.length = 0));
}

export const bearer = (t: string) => 'Bearer ' + t;
