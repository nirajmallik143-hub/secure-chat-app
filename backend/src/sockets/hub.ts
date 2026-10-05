import { Server } from 'socket.io';

let io: Server | undefined;

export const setIO = (s: Server) => {
  io = s;
};

export const emitToUser = (userId: string, event: string, payload: unknown) => {
  io?.to(`user:${userId}`).emit(event, payload);
};
