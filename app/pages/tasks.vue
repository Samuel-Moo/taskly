<template>
  <div class="relative z-10 max-w-5xl">
    <p class="section-kicker in">Today</p>
    <h1 class="page-title">Tasks</h1>
    <p class="page-subtitle">Focus on what moves the work forward.</p>

    <div class="mt-8 grid gap-3">
      <div class="rounded-lg card-surface px-4 py-4 flex items-center justify-between">
        <div>
          <p class="text-sm font-semibold text-12161e">Finalize project brief</p>
          <p class="mt-1 text-xs text-91949b">Due today • High priority</p>
        </div>
        <span class="text-xs font-semibold text-575a64">In progress</span>
      </div>
      <div class="rounded-lg card-surface px-4 py-4 flex items-center justify-between">
        <div>
          <p class="text-sm font-semibold text-12161e">Review API endpoints</p>
          <p class="mt-1 text-xs text-91949b">Tomorrow • Medium priority</p>
        </div>
        <span class="text-xs font-semibold text-575a64">Queued</span>
      </div>
      <div class="rounded-lg card-surface px-4 py-4 flex items-center justify-between">
        <div>
          <p class="text-sm font-semibold text-12161e">Share sprint update</p>
          <p class="mt-1 text-xs text-91949b">Friday • Low priority</p>
        </div>
        <span class="text-xs font-semibold text-575a64">Scheduled</span>
      </div>
    </div>
  </div>
</template>
