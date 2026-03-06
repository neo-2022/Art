export interface WorkerTask<TPayload = unknown> {
  id: string;
  type: string;
  payload: TPayload;
}

export interface WorkerResult<TData = unknown> {
  id: string;
  ok: boolean;
  data?: TData;
  error?: string;
}

export function createWorkerRuntime() {
  return {
    async runTask<TPayload>(task: WorkerTask<TPayload>): Promise<WorkerResult<TPayload>> {
      if (!task.id || !task.type) {
        return {
          id: task.id || "unknown",
          ok: false,
          error: "invalid_task"
        };
      }
      return {
        id: task.id,
        ok: true,
        data: task.payload
      };
    }
  };
}
