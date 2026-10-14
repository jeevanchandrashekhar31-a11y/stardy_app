enum Difficulty {
  beginner,
  intermediate,
  advanced,
  unknown
}

Difficulty difficultyFromString(String? value) {
  if (value == null) return Difficulty.unknown;
  switch (value.toUpperCase()) {
    case 'BEGINNER': return Difficulty.beginner;
    case 'INTERMEDIATE': return Difficulty.intermediate;
    case 'ADVANCED': return Difficulty.advanced;
    default: return Difficulty.unknown;
  }
}

enum CourseCategory {
  creative,
  business,
  tech,
  unknown
}

CourseCategory categoryFromString(String? value) {
  if (value == null) return CourseCategory.unknown;
  switch (value.toUpperCase()) {
    case 'CREATIVE': return CourseCategory.creative;
    case 'BUSINESS': return CourseCategory.business;
    case 'TECH': return CourseCategory.tech;
    default: return CourseCategory.unknown;
  }
}

enum ContentType {
  video,
  audio,
  text,
  unknown
}

ContentType contentTypeFromString(String? value) {
  if (value == null) return ContentType.unknown;
  switch (value.toUpperCase()) {
    case 'VIDEO': return ContentType.video;
    case 'AUDIO': return ContentType.audio;
    case 'TEXT': return ContentType.text;
    default: return ContentType.unknown;
  }
}

enum ResourceType {
  link,
  file,
  unknown
}

ResourceType resourceTypeFromString(String? value) {
  if (value == null) return ResourceType.unknown;
  switch (value.toUpperCase()) {
    case 'LINK': return ResourceType.link;
    case 'FILE': return ResourceType.file;
    default: return ResourceType.unknown;
  }
}
