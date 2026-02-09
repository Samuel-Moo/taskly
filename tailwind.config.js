import defaultTheme from 'tailwindcss/defaultTheme'

export default {
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        'fcfcfc': 'var(--color-fcfcfc)',
        '12161e': 'var(--color-12161e)',
        '656976': 'var(--color-656976)',
        'c2c3c7': 'var(--color-c2c3c7)',
        '91949b': 'var(--color-91949b)',
        '232730': 'var(--color-232730)',
        '575a64': 'var(--color-575a64)',
      },
      padding: {
        '2.25': '0.563rem',
      },
      maxWidth: {
        '75': '18.75rem',
      },
      fontFamily: {
        sans: ['SuisseIntl', ...defaultTheme.fontFamily.sans]
      }
    }
  }
}
